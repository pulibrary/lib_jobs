# frozen_string_literal: true
require 'archivesspace/client'
require 'nokogiri'
require 'fileutils'

module AspaceVersionControl
  # rubocop:disable Metrics/ClassLength
  class GetAgentsJob < LibJob
    attr_reader :repo_eacs

    def initialize(local_git_lab_eacs_dir: Rails.application.config.aspace.local_git_lab_eacs_dir)
      super(category: "Agents_export")
      @errors = []
      @local_git_lab_eacs_dir = local_git_lab_eacs_dir
    end

    def aspace_login
      aspace_client(aspace_config)
    end

    def aspace_config
      raise "Missing required environment variables: ASPACE_URL, ASPACE_USER, or ASPACE_PASSWORD" unless ENV['ASPACE_URL'] && ENV['ASPACE_USER'] && ENV['ASPACE_PASSWORD']

      @config ||= ArchivesSpace::Configuration.new({
                                                     base_uri: ENV['ASPACE_URL'],
                                                     username: ENV['ASPACE_USER'],
                                                     password: ENV['ASPACE_PASSWORD'],
                                                     throttle: 0,
                                                     verify_ssl: false
                                                   })
    end

    def aspace_client(config)
      @client ||= ArchivesSpace::Client.new(config).login
    rescue => error
      Rails.logger.error("Failed to connect to ArchivesSpace: #{error.message}")
      @errors << "ArchivesSpace connection failed: #{error.message}"
      raise error
    end

    def handle(data_set:)
      aspace_login
      Rails.logger.info("Opening Repo at #{@local_git_lab_eacs_dir}")
      GitLab.new(repo_path: @local_git_lab_eacs_dir).update(path: @local_git_lab_eacs_dir)

      # We only have one repo for EACs
      prepare_and_commit_to_git_lab(1, "eacs")

      data_set.data = report
      data_set.report_time = Time.zone.now
      data_set
    end

    def report
      if @errors.empty?
        "Agents successfully exported."
      else
        @errors.join(', ')
      end
    end

    def list_family_agents
      @family_agents ||= @client.get("agents/families", {
                                       query: { all_ids: true }
                                     }).parsed
    end

    def list_corporate_entities_agents
      @corporate_entities_agents ||= @client.get('agents/corporate_entities', {
                                                   query: { all_ids: true }
                                                 }).parsed
    end

    def list_person_agents
      @person_agents ||= @client.get('agents/people', {
                                       query: { all_ids: true }
                                     }).parsed
    end

    def get_archival_context_xml(id, agent_type)
      # repository 1 is the global repository in aspace that has all the agents
      xml_str_body = @client.get("/repositories/1/archival_contexts/#{agent_type}/#{id}.xml").body
      doc = Nokogiri::XML(xml_str_body)

      filename_base = generate_cpf_filename(doc, id, agent_type)

      {
        xml_content: doc.to_xml,
        filename: "#{filename_base}.CPF.xml"
      }
    end

    # Methods to use separately if we want to schedule them individually
    # or run them ad hoc

    def get_person_archival_context_xml(id)
      get_archival_context_xml(id, 'people')
    end

    def get_family_archival_context_xml(id)
      get_archival_context_xml(id, 'families')
    end

    def get_corporate_entity_archival_context_xml(id)
      get_archival_context_xml(id, 'corporate_entities')
    end

    def write_cpf_to_file(dir, id, agent_type)
      Rails.logger.info("Processing CPF for #{agent_type}/#{id}")

      cpf_data = get_archival_context_xml(id, agent_type)
      filename = "#{dir}/#{cpf_data[:filename]}"

      File.open(filename, "w") do |file|
        file << cpf_data[:xml_content]
      end

      Rails.logger.info("Wrote CPF XML to #{filename}")
      cpf_data[:filename]
    rescue => error
      err = "Unable to process CPF for #{agent_type}/#{id}: #{error.message}"
      log_stdout(err)
      log_stderr(err)
    end

    # rubocop:disable Metrics/MethodLength
    def process_all_cpf_files(agent_type, output_dir, chunk_size: 500, start_from: 0)
      agent_ids = get_agent_ids_by_type(agent_type)
      total_count = agent_ids.count

      Rails.logger.info("Processing #{total_count} #{agent_type} agents for CPF files (starting from #{start_from})")
      FileUtils.mkdir_p(output_dir)

      checkpoint_file = "#{output_dir}/#{agent_type}_checkpoint.txt"
      start_from = resolve_start_position(checkpoint_file, start_from)

      config = {
        output_dir: output_dir,
        start_from: start_from,
        total_count: total_count,
        chunk_size: chunk_size,
        checkpoint_file: checkpoint_file
      }
      processed_count = process_agent_batch(agent_ids, agent_type, config)

      cleanup_checkpoint(checkpoint_file)
      Rails.logger.info("Completed processing: #{processed_count} #{agent_type} agents successful out of #{total_count - start_from} attempted")
      processed_count
    end
    # enable Metrics/MethodLength

    # Methods for each agent type in case we want to run them separately
    def process_all_person_cpf_files(output_dir, chunk_size: 500, start_from: 0)
      process_all_cpf_files('people', output_dir, chunk_size: chunk_size, start_from: start_from)
    end

    def process_all_family_cpf_files(output_dir, chunk_size: 500, start_from: 0)
      process_all_cpf_files('families', output_dir, chunk_size: chunk_size, start_from: start_from)
    end

    def process_all_corporate_entity_cpf_files(output_dir, chunk_size: 500, start_from: 0)
      process_all_cpf_files('corporate_entities', output_dir, chunk_size: chunk_size, start_from: start_from)
    end

    private

    # even though we could use the hardcoded repo 1 and path eacs,
    # keep the method more generic for possible future use
    def prepare_and_commit_to_git_lab(repo, path)
      git_lab_repo_path = repo_path(@local_git_lab_eacs_dir, path)
      Rails.logger.info("Preparing commit to GitLab for #{git_lab_repo_path}")

      make_directories(git_lab_repo_path)
      process_all_agent_types_to_directory(git_lab_repo_path)
      GitLab.new(repo_path: @local_git_lab_eacs_dir).commit_eacs_to_git(path: path)
    rescue Git::Error => error
      Rails.logger.error("Error updating EACs using GitLab for repo #{repo} at path #{path}.\nError: #{error}")
    end

    def process_all_agent_types_to_directory(output_dir)
      Rails.logger.info("Processing all agent types to #{output_dir}")

      # Process each agent type and save to the output directory
      ['people', 'families', 'corporate_entities'].each do |agent_type|
        Rails.logger.info("Processing #{agent_type} agents")
        process_all_cpf_files(agent_type, output_dir, chunk_size: 500, start_from: 0)
      end
    end

    def repo_path(local_git_lab_dir, path)
      File.join(local_git_lab_dir, path)
    end

    def make_directories(git_lab_repo_path)
      FileUtils.mkdir_p(git_lab_repo_path)
    end

    def get_agent_ids_by_type(agent_type)
      case agent_type
      when 'people'
        list_person_agents
      when 'families'
        list_family_agents
      when 'corporate_entities'
        list_corporate_entities_agents
      else
        raise "Unknown agent type: #{agent_type}"
      end
    end

    def resolve_start_position(checkpoint_file, start_from)
      if File.exist?(checkpoint_file) && start_from.zero?
        checkpoint_position = File.read(checkpoint_file).to_i
        Rails.logger.info("Resuming from checkpoint: #{checkpoint_position}")
        checkpoint_position
      else
        start_from
      end
    end

    def process_agent_batch(agent_ids, agent_type, config)
      processed_count = 0
      output_dir = config[:output_dir]
      start_from = config[:start_from]
      total_count = config[:total_count]
      chunk_size = config[:chunk_size]
      checkpoint_file = config[:checkpoint_file]

      agent_ids.drop(start_from).each_with_index do |id, relative_index|
        absolute_index = start_from + relative_index

        processed_count += 1 if process_single_agent(id, agent_type, output_dir, absolute_index)

        handle_progress_and_checkpoints(absolute_index, total_count, agent_type, chunk_size, checkpoint_file)
      end

      processed_count
    end

    def process_single_agent(id, agent_type, output_dir, absolute_index)
      write_cpf_to_file(output_dir, id, agent_type)
      true
    rescue => error
      Rails.logger.error("Failed to process #{agent_type} agent #{id} at index #{absolute_index}: #{error.message}")
      @errors << "#{agent_type} agent #{id}: #{error.message}"
      false
    end

    def handle_progress_and_checkpoints(absolute_index, total_count, agent_type, chunk_size, checkpoint_file)
      Rails.logger.info("Processed #{absolute_index + 1}/#{total_count} #{agent_type} agents") if ((absolute_index + 1) % 100).zero?

      # Save checkpoint every chunk_size records
      if ((absolute_index + 1) % chunk_size).zero?
        File.write(checkpoint_file, absolute_index + 1)
        Rails.logger.info("Checkpoint saved at #{absolute_index + 1}")
        sleep(2)
      elsif ((absolute_index + 1) % 20).zero?
        sleep(0.05) # don't overwhelm the API with requests
      end
    end

    def cleanup_checkpoint(checkpoint_file)
      File.delete(checkpoint_file) if File.exist?(checkpoint_file)
    end

    def generate_cpf_filename(doc, id, agent_type)
      namespace = { 'eac' => 'urn:isbn:1-931666-33-4' }

      surname = doc.at_xpath('//eac:nameEntry/eac:part[@localType="surname"]', namespace)&.text
      forename = doc.at_xpath('//eac:nameEntry/eac:part[@localType="forename"]', namespace)&.text

      # Build name parts if they exist
      name_parts = []
      name_parts << surname.gsub(/\s+/, '').upcase if surname
      name_parts << forename.gsub(/\s+/, '').upcase if forename

      # Concatenate name parts, agent_type, and agent_id
      filename_parts = []
      filename_parts << name_parts.join('_') if name_parts.any?
      filename_parts << agent_type
      filename_parts << id.to_s

      filename_parts.join('_')
    end

    def log_stderr(stderr_str)
      @errors << stderr_str unless stderr_str.empty?
    end

    def log_stdout(stdout_str)
      Rails.logger.info(stdout_str) unless stdout_str.empty?
    end
  end
  # rubocop:enable Metrics/ClassLength
end
