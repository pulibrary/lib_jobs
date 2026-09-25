# frozen_string_literal: true
module Aspace2alma
  # Exports marcXML for archival_objects
  class SendComponentMarcxmlToAlmaJob < LibJob
    CATEGORY = 'Aspace2Alma_component'

    FILENAME = 'marcao_export.xml'
    OLD_FILENAME = 'marcao_export_old.xml'
    SFTP_DIR = '/alma/aspace'

    # ArchivesSpace stores Solr dates in UTC ("2026-06-01T00:00:00Z")
    SOLR_TIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ'

    # from MarcAOExporter::WINDOW_SECONDS: makes sure we catch ao's saved after the run started
    WINDOW_SECONDS = 5.seconds

    # how far back to look on the very first run
    DEFAULT_LOOKBACK = 1.day

    # retries
    RETRY_ATTEMPTS = 3
    NETWORK_ERRORS = [Errno::ECONNRESET, Errno::ECONNABORTED, Errno::ETIMEDOUT, Errno::ECONNREFUSED].freeze
    ASPACE_ERRORS = [Net::ReadTimeout, Net::OpenTimeout, *NETWORK_ERRORS].freeze
    SFTP_ERRORS = [Net::SSH::Disconnect, Net::SSH::ConnectionTimeout, *NETWORK_ERRORS].freeze

    def initialize
      super(category: CATEGORY)
    end

    private

    def handle(data_set:)
      started_at = Time.zone.now

      # rename old file
      rename_previous_file

      with_retries(ASPACE_ERRORS, 'logging into ArchivesSpace') { aspace_login }
      since = last_run_time

      ao_jsons = get_all_repo_uris.flat_map { |repo_uri| modified_archival_objects_for_repo(repo_uri:, since:) }
      deliver(ao_jsons) unless ao_jsons.empty?

      Rails.logger.info("#{self.class}: exported #{ao_jsons.size} archival object record(s) modified since #{since}")
      data_set.report_time = started_at
      data_set
    end

    def modified_archival_objects_for_repo(repo_uri:, since:)
      repo_id = get_repo_id_from_uri(repo_uri)

      flagged_resources(repo_uri:, repo_id:).flat_map do |resource|
        ao_since = modified_since?(resource, since) ? nil : since
        resolved_modified_archival_objects(repo_id:, resource_uri: resource['uri'], since: ao_since)
      end
    end

    # fetch all resource records and filter on the flag
    def flagged_resources(repo_uri:, repo_id:)
      resource_ids = with_retries(ASPACE_ERRORS, "listing resources in #{repo_uri}") do
        @client.get("#{repo_uri}/resources", query: { all_ids: true }).parsed
      end

      resolved_objects(repo_id, resource_ids, 'resources', [])
        .select { |resource| resource.dig('user_defined', flag_field) }
    end

    def modified_since?(record, since)
      record['system_mtime'].present? && Time.zone.parse(record['system_mtime']) >= since
    end

    def flag_field
      Rails.application.config.aspace.component_export_flag_field
    end

    def resolved_modified_archival_objects(repo_id:, resource_uri:, since:)
      ao_ids = modified_archival_object_ids(repo_id:, resource_uri:, since:)
      return [] if ao_ids.empty?

      resolved_objects(repo_id, ao_ids, 'archival_objects', Aspace2alma::ArchivalObjectRecord.resolves)
    end

    def resolved_objects(repo_id, ids, record_type, resolves)
      batches = with_retries(ASPACE_ERRORS, "fetching #{record_type} from repository #{repo_id}") do
        get_resolved_objects_from_ids(repo_id, ids, record_type, resolves)
      end
      batches.flatten.uniq { |record| record['uri'] }
    end

    def modified_archival_object_ids(repo_id:, resource_uri:, since:)
      query = %(resource:"#{resource_uri}")
      query += %( AND system_mtime:[#{since.utc.strftime(SOLR_TIME_FORMAT)} TO *]) if since
      ids = []
      page = 1

      loop do
        response = with_retries(ASPACE_ERRORS, "searching #{resource_uri} for modified archival objects") do
          @client.get("/repositories/#{repo_id}/search",
                      query: { q: query, type: ['archival_object'], page:, page_size: 250 }).parsed
        end
        ids.concat(response['results'].map { |result| result['uri'].split('/').last.to_i })
        break if page >= response['last_page']

        page += 1
      end

      ids
    end

    # don't send the same file twice
    def rename_previous_file
      with_retries(SFTP_ERRORS, 'rename old file') do
        Aspace2almaHelper.remove_file("#{SFTP_DIR}/#{OLD_FILENAME}")
        Aspace2almaHelper.rename_file("#{SFTP_DIR}/#{FILENAME}", "#{SFTP_DIR}/#{OLD_FILENAME}")
      end
    end

    def deliver(ao_jsons)
      File.write(FILENAME, Aspace2alma::ArchivalObjectRecord.collection_to_marc(ao_jsons))
      with_retries(SFTP_ERRORS, "uploading #{FILENAME}") { Aspace2almaHelper.alma_sftp(FILENAME) }
    end

    def with_retries(errors, description)
      attempt = 0
      begin
        yield
      rescue *errors => error
        attempt += 1
        raise if attempt > RETRY_ATTEMPTS

        Rails.logger.warn("#{self.class}: #{error.class} ('#{error.message}') while #{description}, " \
                          "retry #{attempt} of #{RETRY_ATTEMPTS} in #{attempt} second(s)")
        sleep(attempt)
        retry
      end
    end

    def last_run_time
      last_success = DataSet.where(category: CATEGORY, status: true).order(report_time: :desc).first
      (last_success&.report_time || DEFAULT_LOOKBACK.ago) - WINDOW_SECONDS
    end
  end
end
