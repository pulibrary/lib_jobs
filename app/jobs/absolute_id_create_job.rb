class AbsoluteIdCreateJob < ApplicationJob
  def perform(attributes)
    absolute_id_params = attributes[:absolute_id]

    repository_param = absolute_id_params[:repository]
    repository_id = repository_param[:id]
    repository_uri = repository_param[:uri]
    repository = client.find_repository(uri: repository_uri)

    resource_param = absolute_id_params[:resource]
    container_param = absolute_id_params[:container]

    resource_refs = client.find_resources_by_ead_id(repository_id: repository_id, ead_id: resource_param)
    raise(ArgumentError, "Failed to resolve the repository resources for #{resource_param} in repository #{repository_id}") if resource_refs.empty?

    resource = repository.build_resource_from(refs: resource_refs)

    container_docs = client.search_top_containers_by(repository_id: repository_id, query: container_param)
    raise(ArgumentError, "Failed to resolve the containers for #{container_param} in repository #{repository_id}") if container_docs.empty?

    top_container = repository.build_top_container_from(documents: container_docs)

    build_attributes = absolute_id_params.deep_dup

    location_resource = location_attributes(build_attributes[:location])
    build_attributes[:location] = location_resource

    container_profile_resource = container_profile_attributes(build_attributes[:container_profile])
    build_attributes[:container_profile] = container_profile_resource

    build_attributes[:repository] = repository_attributes(build_attributes[:repository])

    build_attributes[:resource] = resource_attributes(resource)

    build_attributes[:container] = container_attributes(top_container)

    persisted = AbsoluteId.where(location: location_resource.to_json, container_profile: container_profile_resource.to_json)
    index = child_index
    if !persisted.empty?
      index += persisted.last.index + 1
    end
    build_attributes[:index] = index

    # Update the barcode
    new_barcode_value = build_attributes[:barcode]
    new_barcode = AbsoluteIds::Barcode.new(new_barcode_value)
    new_barcode = new_barcode + child_index
    build_attributes[:barcode] = new_barcode.value

    AbsoluteId.generate(**build_attributes)
  end

  private

  def client
    @client ||= begin
                  new_client = LibJobs::ArchivesSpace::Client.source
                  new_client.login
                  new_client
                end
  end
end
