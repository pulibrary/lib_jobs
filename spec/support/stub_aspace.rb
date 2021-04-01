# frozen_string_literal: true

module AspaceStubbing
  def stub_aspace_login
    stub_request(:post, 'https://aspace.test.org/staff/api/users/test/login?password=password').to_return(status: 200, body: { session: '1' }.to_json, headers: { "Content-Type": 'application/json' })
  end

  def stub_container_profiles
    stub_request(:get, 'https://aspace.test.org/staff/api/container_profiles?page=1&page_size=100000')
      .to_return(
        status: 200,
        body: File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'container_profiles.json')),
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_batch_update_container_profile(uri:, top_container_ids:, repository_id:)
    response_body = {
      status: 'Updated',
      id: 0
    }

    stub_request(:post, "https://aspace.test.org/staff/api/repositories/#{repository_id}/top_containers/batch/container_profile?container_profile_uri=#{uri}&ids%5B%5D=#{top_container_ids}")
      .with(
      body: "{}",
      headers: {
        'Content-Length' => 'nnnn',
        'Content-Type' => 'application/json'
      }
    )
      .to_return(
      status: 200,
      body: JSON.generate(response_body),
      headers: { "Content-Type": 'application/json' }
    )
  end

  def stub_batch_update_location(uri:, top_container_ids:, repository_id:)
    response_body = {
      status: 'Updated',
      id: 0
    }

    stub_request(:post, "https://aspace.test.org/staff/api/repositories/#{repository_id}/top_containers/batch/location?location_uri=#{uri}&ids%5B%5D=#{top_container_ids}")
      .with(
      body: "{}",
      headers: {
        'Content-Length' => 'nnnn',
        'Content-Type' => 'application/json'
      }
    )
      .to_return(
      status: 200,
      body: JSON.generate(response_body),
      headers: { "Content-Type": 'application/json' }
    )
  end

  def stub_locations
    stub_request(:get, 'https://aspace.test.org/staff/api/locations?page=1&page_size=100000')
      .to_return(
        status: 200,
        body: File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'locations.json')),
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_location(location_id:)
    uri = "/locations/#{location_id}"
    path = Rails.root.join('spec', 'fixtures', 'archives_space', 'locations', "#{location_id}.json")
    cache_path(uri: uri, path: path)
    stub_request(:get, "https://aspace.test.org/staff/api#{uri}")
      .to_return(
        status: 200,
        body: File.open(path),
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_repository(repository_id:)
    uri = "/repositories/#{repository_id}"
    path = Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories', repository_id.to_s, 'repository.json')
    cache_path(uri: uri, path: path)
    stub_request(:get, "https://aspace.test.org/staff/api#{uri}")
      .to_return(
        status: 200,
        body: File.open(path),
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_resource_find_by_id(repository_id:, identifier:, resource_id:)
    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/find_by_id/resources?identifier[]=[\"#{identifier}\"]")
      .to_return(
        status: 200,
        body: { resources: [{ ref: "/repositories/#{repository_id}/resources/#{resource_id}" }] }.to_json,
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_repository_top_containers(repository_id:, error: false)
    if error
      stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/top_containers?page=1&page_size=100000&resolve[]=container_locations")
        .to_return(
          status: 500,
          body: 'Something broke'
        )
    else
      path = Rails.root.join('spec', 'fixtures', 'archives_space', "top_containers_#{repository_id}_page1.json")
      uri = "/repositories/#{repository_id}/top_containers?page=1&page_size=100000&resolve[]=container_locations"
      cache_path(path: path, uri: uri)
      stub_request(:get, "https://aspace.test.org/staff/api#{uri}")
        .to_return(
          status: 200,
          body: File.open(path),
          headers: { "Content-Type": 'application/json' }
        )
    end
  end

  def stub_repositories
    stub_request(:get, 'https://aspace.test.org/staff/api/repositories?page=1')
      .to_return(
        status: 200,
        body: File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories.json')),
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_resource(resource_id:, repository_id:)
    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/resources/#{resource_id}")
      .to_return(
        status: 200,
        body: File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories', repository_id.to_s, "#{resource_id}.json")),
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_search_repository_children(repository_id:, type: 'top_container')
    response_body = File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories', "search_top_containers.json"))

    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/search?type%5B%5D=#{type}&page=1")
      .to_return(
        status: 200,
        body: response_body,
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_top_containers(ead_id:, repository_id:)
    response_body = File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories', "search_top_containers.json"))

    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/search?page=1&q=collection_identifier_u_stext:#{ead_id}&type%5B%5D=top_container")
      .to_return(
        status: 200,
        body: response_body,
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_resources(repository_id:)
    resources_fixture_file_path = Rails.root.join('spec', 'fixtures', 'archives_space', 'resources.json')
    resources_fixture = File.read(resources_fixture_file_path)

    parsed_response = JSON.parse(resources_fixture)
    response_results = parsed_response["results"]
    one_child_response = {
      "first_page" => parsed_response["first_page"],
      "last_page" => parsed_response["last_page"],
      "this_page" => parsed_response["this_page"],
      "total" => parsed_response["total"],
      "results" => [response_results.first]
    }

    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/resources?page=1&page_size=100000")
      .to_return(
        status: 200,
        body: JSON.generate(one_child_response),
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_archival_object(archival_object_id:, repository_id:)
    path = Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories', repository_id.to_s, "archival_object_#{archival_object_id}.json")
    cache_path(uri: "/repositories/#{repository_id}/archival_objects/#{archival_object_id}", path: path)
    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/archival_objects/#{archival_object_id}")
      .to_return(
        status: 200,
        body: File.open(path),
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_top_container(repository_id:, top_container_id:)
    path = Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories', repository_id.to_s, "top_container_#{top_container_id}.json")
    cache_path(uri: "/repositories/#{repository_id}/top_containers/#{top_container_id}", path: path)
    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/top_containers/#{top_container_id}")
      .to_return(
        status: 200,
        body: File.open(path),
        headers: { "Content-Type": 'application/json' }
      )
  end

  # It took too long to manually create the mocks for navigating the whole tree,
  # so this shortcut function grabs it from the real API if necessary. Kind of
  # like on-demand VCR.
  def cache_path(uri:, path:)
    return if File.exist?(path)

    WebMock.disable!
    client = LibJobs::ArchivesSpace::Client.new(LibJobs::ArchivesSpace::Configuration.new(LibJobs.all_environment_config['development']['archivesspace']['source'].symbolize_keys))
    client.login
    result = client.get(uri)
    FileUtils.mkdir_p(Pathname.new(path).dirname)
    File.open(path, 'w') do |f|
      f.write(result.body)
    end
    WebMock.enable!
  end

  def stub_tree_root(resource_id:, repository_id:)
    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/resources/#{resource_id}/tree/root")
      .to_return(
        status: 200,
        body: File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories', repository_id.to_s, "#{resource_id}_tree_root.json")),
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_tree_node(resource_id:, repository_id:, archival_object_id:)
    path = Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories', repository_id.to_s, "#{resource_id}_tree_#{archival_object_id}.json")
    cache_path(uri: "/repositories/#{repository_id}/resources/#{resource_id}/tree/node?node_uri=/repositories/#{repository_id}/archival_objects/#{archival_object_id}", path: path)
    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/resources/#{resource_id}/tree/node?node_uri=/repositories/#{repository_id}/archival_objects/#{archival_object_id}")
      .to_return(
        status: 200,
        body: File.open(path),
        headers: { "Content-Type": 'application/json' }
      )
  end
end

RSpec.configure do |config|
  config.include AspaceStubbing
end
