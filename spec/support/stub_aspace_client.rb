# frozen_string_literal: true
module ASpaceClientStubbing
  def stub_aspace_source_client(client: nil)
    login_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'login.json')
    login_fixture = File.read(login_fixture_file_path)

    client ||= LibJobs::ArchivesSpace::Client.source
    allow(client).to receive(:login).and_return(login_fixture)
    client
  end
  alias stub_aspace_client stub_aspace_source_client

  def stub_aspace_sync_client(client: nil)
    login_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'login.json')
    login_fixture = File.read(login_fixture_file_path)

    client ||= LibJobs::ArchivesSpace::Client.sync
    allow(client).to receive(:login).and_return(login_fixture)
    client
  end

  def stub_aspace_location(location_id:, client: nil)
    client ||= stub_aspace_client

    location_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'location.json')
    location_fixture = File.read(location_fixture_file_path)

    location_response_status = double
    location_response = double
    allow(
      location_response_status
    ).to receive(:code).and_return("200")
    allow(
      location_response
    ).to receive(:status).and_return(location_response_status)
    allow(location_response).to receive(:body).and_return(location_fixture)

    allow(client).to receive(:get).with("/locations/#{location_id}").and_return(location_response)
    client
  end

  def stub_aspace_top_container(repository_id:, top_container_id:, client: nil)
    client ||= stub_aspace_repository(repository_id: repository_id)

    # Implementing support for TopContainer querying
    # For searching the TopContainers by barcode
    resource_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'top_container.json')
    resource_fixture = File.read(resource_fixture_file_path)

    resource_response_status = double
    resource_response = double
    allow(
      resource_response_status
    ).to receive(:code).and_return("200")
    allow(
      resource_response
    ).to receive(:status).and_return(resource_response_status)
    allow(resource_response).to receive(:body).and_return(resource_fixture)

    allow(client).to receive(:get).with("/repositories/#{repository_id}/top_containers/#{top_container_id}").and_return(resource_response)

    stub_aspace_source_client(client: client)
  end

  def stub_aspace_search_top_containers(repository_id:, barcode: nil, indicator: nil, empty: false, client: nil)
    client ||= stub_aspace_repository(repository_id: repository_id)

    # Implementing support for TopContainer querying
    # For searching the TopContainers by barcode
    top_containers_search_fixture = if empty
                                      top_containers_search_response = {
                                        'response' => {
                                          'docs' => []
                                        }
                                      }
                                      top_containers_search_response.to_json
                                    else
                                      top_containers_search_fixture_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories_top_containers_search.json')
                                      File.read(top_containers_search_fixture_path)
                                    end

    top_container_response_status = double
    top_container_response = double
    allow(top_container_response_status).to receive(:code).and_return("200")
    allow(top_container_response).to receive(:status).and_return(top_container_response_status)
    allow(top_container_response).to receive(:body).and_return(top_containers_search_fixture)

    query_param = if !indicator.nil?
                    [["q", indicator]]
                  elsif !barcode.nil?
                    [["q", barcode]]
                  else
                    ""
                  end
    query = URI.encode_www_form(query_param)

    allow(client).to receive(:get).with("/repositories/#{repository_id}/top_containers/search?#{query}").and_return(top_container_response)

    client
  end

  def stub_aspace_archival_object(repository_id:, archival_object_id:, client: nil)
    client ||= stub_aspace_repository(repository_id: repository_id)

    resource_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'archival_object.json')
    resource_fixture = File.read(resource_fixture_file_path)

    resource_response_status = double
    resource_response = double
    allow(
      resource_response_status
    ).to receive(:code).and_return("200")
    allow(
      resource_response
    ).to receive(:status).and_return(resource_response_status)
    allow(resource_response).to receive(:body).and_return(resource_fixture)

    allow(client).to receive(:get).with("/repositories/#{repository_id}/archival_objects/#{archival_object_id}").and_return(resource_response)

    stub_aspace_source_client(client: client)
  end

  def stub_aspace_resource(repository_id:, resource_id:, ead_id: nil, client: nil)
    default_client = stub_aspace_top_container(repository_id: repository_id, top_container_id: '118092', client: client)

    archival_object_id = '597759'
    client = stub_aspace_archival_object(repository_id: repository_id, archival_object_id: archival_object_id, client: default_client)

    # Stub an empty tree for the child nodes
    resource_tree_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'resource_tree_empty.json')
    resource_tree_fixture = File.read(resource_tree_fixture_file_path)

    resource_tree_response_status = double
    resource_tree_response = double
    allow(resource_tree_response_status).to receive(:code).and_return("200")
    allow(resource_tree_response).to receive(:status).and_return(resource_tree_response_status)
    # allow(resource_tree_response).to receive(:body).and_return(resource_tree_fixture)
    allow(resource_tree_response).to receive(:parsed).and_return(JSON.parse(resource_tree_fixture))

    allow(client).to receive(:get).with("/repositories/#{repository_id}/resources/#{resource_id}/tree/node?node_uri=/repositories/#{repository_id}/archival_objects/#{archival_object_id}").and_return(resource_tree_response)

    # Stub for cases where the client is querying using the EAD ID field for the Resource
    unless ead_id.nil?
      resources_find_results_fixture_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'resources_find_results.json')
      resources_find_results_fixture = File.read(resources_find_results_fixture_path)

      resources_find_results_response_status = double
      resources_find_results_response = double
      allow(
        resources_find_results_response_status
      ).to receive(:code).and_return("200")
      allow(
        resources_find_results_response
      ).to receive(:status).and_return(
        resources_find_results_response_status
      )
      allow(resources_find_results_response).to receive(:parsed).and_return(JSON.parse(resources_find_results_fixture))

      # I am uncertain if this is redundant
      query_params = URI.encode_www_form([["identifier[]", [resource_id].to_json]])
      query_uri_path = "/repositories/#{repository_id}/find_by_id/resources?#{query_params}"
      allow(client).to receive(:get).with(query_uri_path).and_return(resources_find_results_response)

      # I am uncertain if this is redundant
      query_params = URI.encode_www_form([["identifier[]", [ead_id].to_json]])
      query_uri_path = "/repositories/#{repository_id}/find_by_id/resources?#{query_params}"

      allow(client).to receive(:get).with(query_uri_path).and_return(resources_find_results_response)
    end

    # Stub the GET response for the Resource
    resource_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'resource.json')
    resource_fixture = File.read(resource_fixture_file_path)

    resource_response_status = double
    resource_response = double
    allow(
      resource_response_status
    ).to receive(:code).and_return("200")
    allow(
      resource_response
    ).to receive(:status).and_return(resource_response_status)
    allow(resource_response).to receive(:body).and_return(resource_fixture)

    allow(client).to receive(:get).with("/repositories/#{repository_id}/resources/#{resource_id}").and_return(resource_response)

    # Stub the GET response for the child Resources and ArchivalObjects
    resource_tree_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'resource_tree_single_child.json')
    resource_tree_fixture = File.read(resource_tree_fixture_file_path)

    resource_tree_response_status = double
    resource_tree_response = double
    allow(resource_tree_response_status).to receive(:code).and_return("200")
    allow(resource_tree_response).to receive(:status).and_return(resource_tree_response_status)

    allow(resource_tree_response).to receive(:parsed).and_return(JSON.parse(resource_tree_fixture))

    allow(client).to receive(:get).with("/repositories/#{repository_id}/resources/#{resource_id}/tree/root").and_return(resource_tree_response)

    stub_aspace_source_client(client: client)
  end

  def stub_aspace_repository(repository_id:, client: nil)
    if client.nil?
      default_client = stub_aspace_client

      client = stub_aspace_resource(repository_id: repository_id, resource_id: '1870', client: default_client)
    end

    # Stubbing the GET response for the member Resources
    resources_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'resources.json')
    resources_fixture = File.read(resources_fixture_file_path)
    resources_response_status = double
    resources_response = double
    allow(resources_response_status).to receive(:code).and_return("200")
    allow(resources_response).to receive(:status).and_return(resources_response_status)

    parsed_response = JSON.parse(resources_fixture)
    response_results = parsed_response["results"]
    one_child_response = {
      "first_page" => parsed_response["first_page"],
      "last_page" => parsed_response["last_page"],
      "this_page" => parsed_response["this_page"],
      "total" => parsed_response["total"],
      "results" => [response_results.first]
    }
    allow(resources_response).to receive(:body).and_return(JSON.generate(one_child_response))

    # Stubbing the GET response for the repository resource
    repository_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'repository.json')
    repository_fixture = File.read(repository_fixture_file_path)

    repository_response_status = double
    repository_response = double
    allow(repository_response_status).to receive(:code).and_return("200")
    allow(repository_response).to receive(:status).and_return(repository_response_status)
    allow(repository_response).to receive(:body).and_return(repository_fixture)

    allow(client).to receive(:get).with("/repositories/#{repository_id}/resources?page=1&page_size=100000").and_return(resources_response)
    allow(client).to receive(:get).with("/repositories/#{repository_id}").and_return(repository_response)

    stub_aspace_source_client(client: client)
  end
end

RSpec.configure do |config|
  config.include ASpaceClientStubbing
end
