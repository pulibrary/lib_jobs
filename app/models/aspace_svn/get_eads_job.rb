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
      repos = (3..12).to_a
      repos.each do |repo|
        # make directories if they don't already exist
        dir =
          case repo
          when 3
            "#{@aspace_output_base_dir}/eads/mudd/publicpolicy"
          when 4
            "#{@aspace_output_base_dir}/eads/mudd/univarchives"
          when 5
            "#{@aspace_output_base_dir}/eads/mss"
          when 6
            "#{@aspace_output_base_dir}/eads/rarebooks"
          when 7
            "#{@aspace_output_base_dir}/eads/cotsen"
          when 8
            "#{@aspace_output_base_dir}/eads/lae"
          when 9
            "#{@aspace_output_base_dir}/eads/eng"
          when 10
            "#{@aspace_output_base_dir}/eads/selectors"
          when 11
            "#{@aspace_output_base_dir}/eads/ga"
          when 12
            "#{@aspace_output_base_dir}/eads/ea"
          end
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

        # get resource ids
        resource_ids = @client.get("/repositories/#{repo}/resources", {
                                     query: {
                                       all_ids: true
                                     }
                                   }).parsed
        # get eads from ids
        eads =
          resource_ids.map do |id|
            record = @client.get("/repositories/#{repo}/resource_descriptions/#{id}.xml")
            ead = Nokogiri::XML(record.body)
            # i shouldn't have to do this but I do
            ead.remove_namespaces!
            eadid = ead.at_xpath('//eadid/text()')
            # save file with eadid as file name
            file =  File.open("#{dir}/#{eadid}.EAD.xml", "w")
            # add back a default namespace
            ead.child.add_namespace('ead', 'http://www.loc.gov/ead/ead')
            file << ead
            file.close
          end
      end
      data_set.data = report
      data_set.report_time = Time.zone.now
      data_set
    end

    def report
      # item_count = renew_list.renew_item_list.count
      if @errors.empty?
        "EADs successfully exported."
      else
        "There was a problem exporting the EADs."
      end
    end
  end
end
