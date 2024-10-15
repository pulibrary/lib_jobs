# frozen_string_literal: true
require 'archivesspace/client'
require 'nokogiri'
require 'fileutils'

module AspaceSvn
  class GetEadsJob < LibJob
    attr_reader :repos
    def initialize(aspace_output_base_dir: Rails.application.config.aspace.aspace_files_output_path)
      super(category: "EAD_export")
      @errors = []
      @svn_username = Rails.application.config.aspace.svn_username
      @svn_password = Rails.application.config.aspace.svn_password
      @aspace_output_base_dir = aspace_output_base_dir
      @repos = Rails.application.config.aspace.repos
    end

    def aspace_login
      # configure access
      @config = ArchivesSpace::Configuration.new({
                                                   base_uri: ENV['ASPACE_URL'],
                                                   base_repo: "",
                                                   username: ENV['ASPACE_USER'],
                                                   password: ENV['ASPACE_PASSWORD'],
                                                   throttle: 0,
                                                   verify_ssl: false
                                                 })
      # log in
      @client = ArchivesSpace::Client.new(@config).login
    end

    def handle(data_set:)
      aspace_login
      repos.each do |repo, path|
        # make directories if they don't already exist
        make_directories(path)
        # get resource ids
        get_resource_ids_for_repo(repo)
        # get eads from ids
        get_eads_from_ids(@dir, repo, @resource_ids)
        commit_eads_to_svn(path:)
      end
      data_set.data = report
      data_set.report_time = Time.zone.now
      data_set
    end

    def make_directories(path)
      @dir = "#{@aspace_output_base_dir}/#{path}"
      FileUtils.mkdir_p(@dir) unless Dir.exist?(@dir)
    end

    def get_resource_ids_for_repo(repo)
      @resource_ids = @client.get("/repositories/#{repo}/resources", {
                                    query: { all_ids: true }
                                  }).parsed
      @resource_ids
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
      ead.remove_namespaces!
      eadid = ead.at_xpath('//eadid/text()')
      file =  File.open("#{dir}/#{eadid}.EAD.xml", "w")
      ead.child.add_namespace('ead', 'http://www.loc.gov/ead/ead')
      file << ead
      file.close
    rescue Nokogiri::XML::SyntaxError
      err = "Unable to process XML for record #{repo}/#{id}, please check the source XML for errors"
      log_stdout(err)
      log_stderr(err)
    end

    def commit_eads_to_svn(path: nil)
      svn_update
      svn_add
      svn_commit(path:)
    end

    def svn_update
      stdout_str, stderr_str, status = Open3.capture3("svn update #{@aspace_output_base_dir}")
      log_stdout(stdout_str)
      log_stderr(stderr_str)
      return unless status.success? == false
      log_stderr("Update failed")
    end

    def svn_add
      stdout_str, stderr_str, status = Open3.capture3("svn add --force #{@aspace_output_base_dir}")
      log_stdout(stdout_str)
      log_stderr(stderr_str)
      return unless status.success? == false
      log_stderr("SVN Add failed")
    end

    def svn_commit(path: nil)
      stdout_str, stderr_str, status = Open3.capture3("svn commit #{@aspace_output_base_dir}/#{path} -m 'monthly snapshot of ASpace EADs' --username #{@svn_username} --password #{@svn_password}")
      log_stdout(stdout_str)
      log_stderr(stderr_str)
      return unless status.success? == false
      log_stderr("Commit failed")
    end

    def log_stderr(stderr_str)
      @errors << stderr_str unless stderr_str.empty?
    end

    def log_stdout(stdout_str)
      Rails.logger.info(stdout_str) unless stdout_str.empty?
    end
  end
end
