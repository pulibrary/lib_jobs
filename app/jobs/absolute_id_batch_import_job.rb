
class AbsoluteIdBatchImportJob < ApplicationJob
  def perform(barcode_entries:, sequence_entries:)
    @barcode_entries = barcode_entries
    @sequence_entries = sequence_entries

    entries.each do |row|
      AbsoluteIdImportJob.perform_now(**row.to_h)
    end
  end

  def barcode_rows
    output = {}

    @barcode_entries[(1..-1)].each do |barcode_entry|
      primary_key = barcode_entry[0]
      output[primary_key] = barcode_entry[1]
    end

    output
  end

  def entries
    output = []

    @sequence_entries[(1..-1)].each do |sequence_entry|

      prefix = sequence_entry[2]
      container_index = sequence_entry[10]
      call_number = sequence_entry[11]
      repo_code = sequence_entry[12]
      container_type = sequence_entry[13]

      repository = current_client.find_repository_by(repo_code: repo_code)

      resource_refs = current_client.find_resources_by_ead_id(repository_id: repository.id, ead_id: call_number)
      resource = build_resource_from(repository_id: repository.id, refs: resource_refs)

      # This needs to be determined
      container_query = "#{container_type}*#{container_index}"
      container_docs = current_client.search_top_containers_by(repository_id: repository.id, query: container_query)
      top_container = build_container_from(repository_id: repository.id, documents: container_docs)
    end

    output
  end
end
