# frozen_string_literal: true
module Aspace2alma
  # This class processes archival containers and constructs MARC XML item records.
  #
  # Class workflow:
  # 1. Load and validate Alma barcode data from CSV files
  # 2. Fetch container records from ArchivesSpace API for a specific resource
  # 3. Sort containers by indicator number for consistent processing order
  # 4. Process each container individually, creating MARC records for valid ones
  # 5. Log successful item record creation for audit and monitoring
  #

  # @example Basic usage
  #   client = ArchivesSpace::Client.new(config)
  #   params = ItemParams.new(marc_doc, tag099_a, logger, nil)
  #   constructor = ItemRecordConstructor.new(client)
  #   constructor.construct_item_records("barcodes.csv", "/repositories/2/resources/123", params)
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
