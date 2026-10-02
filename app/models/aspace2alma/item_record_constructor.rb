# frozen_string_literal: true
module Aspace2alma
  # This class processes archival containers and constructs MARC XML item records.
  #
  # Class workflow:
  # 1. Fetch container records from ArchivesSpace API for a specific resource
  # 2. Sort containers by indicator number for consistent processing order
  # 3. Skip containers that aren't at ReCAP, have no barcode, or whose barcode
  #    is already in Alma (checked through the Alma API by AlmaDuplicateBarcodeCheck)
  # 4. Add a 949 item record for each remaining container and log it
  #
  # @example Basic usage
  #   client = ArchivesSpace::Client.new(config)
  #   params = ItemParams.new(marc_doc, tag099_a, logger)
  #   constructor = ItemRecordConstructor.new(client, AlmaDuplicateBarcodeCheck.new)
  #   constructor.construct_item_records("/repositories/2/resources/123", params)
  #
  # @see ItemRecordUtils for utility functions
  # @see TopContainer for container-specific logic
  # @see ItemParams for parameter structure
  class ItemRecordConstructor
    def initialize(client, barcode_duplicate_check)
      @client = client
      @barcode_duplicate_check = barcode_duplicate_check
    end

    attr_reader :barcode_duplicate_check, :client

    def construct_item_records(resource, params)
      containers = fetch_and_sort_containers(resource)

      return unless containers

      process_containers(containers, params)
    end

        private

    def fetch_containers(resource)
      repo = ItemRecordUtils.extract_repository_id(resource)
      @client.get("repositories/#{repo}/top_containers/search", query: { q: "collection_uri_u_sstr:\"#{resource}\"" })
    end

    def fetch_and_sort_containers(resource)
      containers_unfiltered = fetch_containers(resource)
      return unless containers_unfiltered&.parsed&.dig('response', 'docs')

      ItemRecordUtils.sort_containers_by_indicator(containers_unfiltered.parsed['response']['docs'])
    end

    def process_containers(containers, params)
      containers.select do |container|
        process_single_container(container, params)
      end
    end

    def process_single_container(container, params)
      top_container = TopContainer.new(container)
      return false unless container_valid?(top_container)

      ItemRecordUtils.create_and_log_item_record(container, top_container, params)
      true
    end

    def container_valid?(top_container)
      top_container.valid? && top_container.barcode && !barcode_duplicate_check.duplicate?(top_container.barcode)
    end
  end
end
