# frozen_string_literal: true
require 'archivesspace/client'
require 'nokogiri'
require 'fileutils'

module AspaceSvn
  class GetEadsJob < LibJob
    def initialize(aspace_output_base_dir: Rails.application.config.aspace.aspace_files_output_path)
      super(category: "EAD_export")
      @errors = []
      @svn_username = Rails.application.config.aspace.svn_username
      @svn_password = Rails.application.config.aspace.svn_password
      @svn_host = Rails.application.config.aspace.svn_host
      @aspace_output_base_dir = aspace_output_base_dir
    end

    def aspace_login
      # configure access
      @config = ArchivesSpace::Configuration.new({
                                                   base_uri: ENV['ASPACE_URL'],
                                                   base_repo: "",
                                                   username: ENV['ASPACE_USER'],
                                                   password: ENV['ASPACE_PASSWORD'],
                                                   # page_size: 50,
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
      end
      data_set.data = report
      data_set.report_time = Time.zone.now
      commit_eads_to_svn
      data_set
    end

    def make_directories(path)
      @dir = "#{@aspace_output_base_dir}/#{path}"
      FileUtils.mkdir_p(@dir) unless Dir.exist?(@dir)
    end

    def get_resource_ids_for_repo(repo)
      @resource_ids = @client.get("/repositories/#{repo}/resources", {
                                    query: {
                                      all_ids: true
                                    }
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
        "There was a problem exporting the EADs."
      end
    end

    private

    def repos
      {
        3 => "mudd/publicpolicy",
        4 => "mudd/univarchives",
        5 => "mss",
        6 => "rarebooks",
        7 => "cotsen",
        8 => "lae",
        9 => "eng",
        10 => "selectors",
        11 => "ga",
        12 => "ea"
      }
    end

    # Replace the namespace with the correct loc.gov one,
    # then write the results to the file
    def write_eads_to_file(dir, repo, id)
      Rails.logger.info("Now processing #{repo}/#{id}")
      record = @client.get("/repositories/#{repo}/resource_descriptions/#{id}.xml")
      ead = Nokogiri::XML(record.body)
      ead.remove_namespaces!
      eadid = ead.at_xpath('//eadid/text()')
      file =  File.open("#{dir}/#{eadid}.EAD.xml", "w")
      ead.child.add_namespace('ead', 'http://www.loc.gov/ead/ead')
      file << ead
      file.close
    end

    def commit_eads_to_svn
      svn_update
      svn_add
      svn_commit
    end

    def svn_update
      stdout_str, stderr_str, status = Open3.capture3("svn update #{@aspace_output_base_dir}")
      @errors << stderr_str unless stderr_str.empty?
      Rails.logger.info(stdout_str) unless stdout_str.empty?
    end

    def svn_add
      stdout_str, stderr_str, status = Open3.capture3("svn add --force #{@aspace_output_base_dir}")
      @errors << stderr_str unless stderr_str.empty?
      Rails.logger.info(stdout_str) unless stdout_str.empty?
    end

    def svn_commit
      stdout_str, stderr_str, status = Open3.capture3("svn commit #{@aspace_output_base_dir} -m 'monthly snapshot of ASpace EADs' --username test-username --password test-password")
      @errors << stderr_str unless stderr_str.empty?
      Rails.logger.info(stdout_str) unless stdout_str.empty?
    end
  end
end
