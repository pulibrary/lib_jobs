# frozen_string_literal: true
require 'archivesspace/client'
require 'nokogiri'
require 'fileutils'

# rubocop:disable Metrics/ClassLength
module AspaceVersionControl
  class GetEadsJob < LibJob
    attr_reader :repos
    def initialize(local_svn_dir: Rails.application.config.aspace.local_svn_dir,
                   local_git_lab_dir: Rails.application.config.aspace.local_git_lab_dir)
      super(category: "EAD_export")
      @errors = []
      @local_svn_dir = local_svn_dir
      @local_git_lab_dir = local_git_lab_dir
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
        get_resource_ids_for_repo(repo)
        next unless @resource_ids

        prepare_and_commit_to_svn(repo, path)
        prepare_and_commit_to_git_lab(repo, path)
      end
      data_set.data = report
      data_set.report_time = Time.zone.now
      data_set
    end

    def repo_path(dir, path)
      "#{dir}/#{path}"
    end

    def make_directories(dir)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
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

    # TODO: Remove SVN version once the GitLab version has run successfully for awhile
    def prepare_and_commit_to_svn(repo, path)
      svn_repo_path = repo_path(@local_svn_dir, path)
      make_directories(svn_repo_path)
      get_eads_from_ids(svn_repo_path, repo, @resource_ids)
      svn_errors = Svn.new.commit_eads_to_svn(path:)
      @errors << svn_errors unless svn_errors.empty?
    end

    def prepare_and_commit_to_git_lab(repo, path)
      git_lab_repo_path = repo_path(@local_git_lab_dir, path)
      Rails.logger.info("Preparing commit to GitLab for #{git_lab_repo_path}")

      make_directories(git_lab_repo_path)
      get_eads_from_ids(git_lab_repo_path, repo, @resource_ids)
      GitLab.new.commit_eads_to_git(path:)
    rescue Git::Error => error
      Rails.logger.error("Error updating EADS using GitLab for repo #{repo} at path #{path}.\nError: #{error}")
    end

    # Replace the namespace with the correct loc.gov one,
    # then write the results to the file
    def write_eads_to_file(dir, repo, id)
      Rails.logger.info("Now processing #{repo}/#{id}")
      record = aspace_record(repo, id)
      ead = Nokogiri::XML(record.body)
      rewrite_namespace(dir:, ead:)
    rescue Nokogiri::XML::SyntaxError
      err = "Unable to process XML for record #{repo}/#{id}, please check the source XML for errors"
      log_stdout(err)
      log_stderr(err)
    end

    def aspace_record(repo, id)
      retries ||= 0
      @client.get("/repositories/#{repo}/resource_descriptions/#{id}.xml", {
                    query: { include_daos: true }
                  })
    rescue Net::ReadTimeout => error
      while (retries += 1) <= 3
        Rails.logger.warn("Encountered #{error.class}: '#{error.message}' when connecting at #{Time.now.utc}, retrying in #{retries} second(s)...")
        sleep(retries)
        retry
      end
      Rails.logger.error("Encountered #{error.class}: '#{error.message}' at #{Time.now.utc}, unsuccessful in connecting after #{retries} retries")
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
# rubocop:enable Metrics/ClassLength
