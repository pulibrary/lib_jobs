# frozen_string_literal: true
require 'archivesspace/client'
require 'nokogiri'
require 'fileutils'

module AspaceVersionControl
  class GetEadsJob < LibJob
    attr_reader :repos
    def initialize(aspace_output_base_dir_svn: Rails.application.config.aspace.aspace_files_output_path_svn)
      super(category: "EAD_export")
      @errors = []
      @aspace_output_base_dir_svn = aspace_output_base_dir_svn
      @repos = Rails.application.config.aspace.repos
    end

    def aspace_login
      aspace_client(aspace_config)
    end

    def aspace_config
      @config ||= ArchivesSpace::Configuration.new({
                                                     base_uri: ENV['ASPACE_URL'],
                                                     base_repo: "",
                                                     username: ENV['ASPACE_USER'],
                                                     password: ENV['ASPACE_PASSWORD'],
                                                     throttle: 0,
                                                     verify_ssl: false
                                                   })
    end

    def aspace_client(config)
      @client ||= ArchivesSpace::Client.new(config).login
    end

    def handle(data_set:)
      aspace_login
      repos.each do |repo, path|
        # make directories if they don't already exist
        make_directories(path)
        # get resource ids
        get_resource_ids_for_repo(repo)
        next unless @resource_ids
        # get eads from ids
        get_eads_from_ids(@svn_dir, repo, @resource_ids)
        svn_errors = Svn.new.commit_eads_to_svn(path:)
        GitLab.new.commit_eads_to_git(path:)
        @errors << svn_errors unless svn_errors.empty?
      rescue Git::Error => error
        Rails.logger.error("Error updating EADS using GitLab for repo #{repo} at path #{path}.\nError: #{error}")
      end
      data_set.data = report
      data_set.report_time = Time.zone.now
      data_set
    end

    def make_directories(path)
      @svn_dir = "#{@aspace_output_base_dir_svn}/#{path}"
      FileUtils.mkdir_p(@svn_dir) unless Dir.exist?(@svn_dir)
    end

    def get_resource_ids_for_repo(repo)
      retries ||= 0
      @resource_ids = @client.get("/repositories/#{repo}/resources", {
                                    query: { all_ids: true }
                                  }).parsed

      @resource_ids
    rescue Net::ReadTimeout => error
      while (retries += 1) <= 3
        Rails.logger.warn("Encountered #{error.class}: '#{error.message}' when connecting at #{Time.now.utc}, retrying in #{retries} second(s)...")
        sleep(retries)
        retry
      end
      Rails.logger.error("Encountered #{error.class}: '#{error.message}' at #{Time.now.utc}, unsuccessful in connecting after #{retries} retries")
    end

    def get_eads_from_ids(dir, repo, resource_ids)
      resource_ids.map { |id| write_eads_to_file(dir, repo, id) }
    end

    def report
      if @errors.empty?
        "EADs successfully exported."
      else
        @errors.join(', ')
      end
    end

    private

    # Replace the namespace with the correct loc.gov one,
    # then write the results to the file
    def write_eads_to_file(dir, repo, id)
      Rails.logger.info("Now processing #{repo}/#{id}")
      record = @client.get("/repositories/#{repo}/resource_descriptions/#{id}.xml", {
                             query: { include_daos: true }
                           })
      ead = Nokogiri::XML(record.body)
      rewrite_namespace(dir:, ead:)
    rescue Nokogiri::XML::SyntaxError
      err = "Unable to process XML for record #{repo}/#{id}, please check the source XML for errors"
      log_stdout(err)
      log_stderr(err)
    end

    def rewrite_namespace(dir:, ead:)
      ead.remove_namespaces!
      ead_id = ead.at_xpath('//eadid/text()')
      file = File.open("#{dir}/#{ead_id}.EAD.xml", "w")
      ead.child.add_namespace('ead', 'http://www.loc.gov/ead/ead')
      file << ead
      file.close
    end

    def log_stderr(stderr_str)
      @errors << stderr_str unless stderr_str.empty?
    end

    def log_stdout(stdout_str)
      Rails.logger.info(stdout_str) unless stdout_str.empty?
    end
  end
end
