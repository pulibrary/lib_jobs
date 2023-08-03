# frozen_string_literal: true
require 'archivesspace/client'
require 'nokogiri'
require 'fileutils'

module AspaceSvn
  class GetEadsJob < LibJob
    def initialize(aspace_output_base_dir: Rails.application.config.aspace.aspace_files_output_path)
      super(category: "EAD_export")
      @errors = []
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
        dir = "#{@aspace_output_base_dir}/eads/#{path}"
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

        # get resource ids
        resource_ids = @client.get("/repositories/#{repo}/resources", {
                                     query: {
                                       all_ids: true
                                     }
                                   }).parsed
        # get eads from ids
        resource_ids.map { |id| write_eads_to_file(dir, repo, id) }
      end
      data_set.data = report
      data_set.report_time = Time.zone.now
      data_set
      commit_eads_to_svn
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

    # send eads from temp directory to svn via working copy
    def commit_eads_to_svn
      wc = "path/to/working_copy"
      `cp -r #{@aspace_output_base_dir}/eads #{wc}`
      `svn update #{wc} >&2`
      # add anything that isn't versioned yet
      `svn add --force #{wc} >&2`
      `svn commit #{wc} -m "monthly snapshot of ASpace EAD export" >&2`
    end
  end
end
