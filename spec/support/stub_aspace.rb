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

  def stub_locations
    stub_request(:get, 'https://aspace.test.org/staff/api/locations?page=1&page_size=100000')
      .to_return(
        status: 200,
        body: File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'locations.json')),
        headers: { "Content-Type": 'application/json' }
      )
  end

  # @note Currently only stubs Repository 4, univarchives, because that's what
  # we're using in testing.
  def stub_repository
    stub_request(:get, 'https://aspace.test.org/staff/api/repositories/4')
      .to_return(
        status: 200,
        body: File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'repository.json')),
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
      stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/top_containers?page=1&page_size=100000&resolve[]=container_locations")
        .to_return(
          status: 200,
          body: File.open(Rails.root.join('spec', 'fixtures', 'archives_space', "top_containers_#{repository_id}_page1.json")),
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

  def stub_archival_object(archival_object_id:, repository_id:)
    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/archival_objects/#{archival_object_id}")
      .to_return(
        status: 200,
        body: File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories', repository_id.to_s, "archival_object_#{archival_object_id}.json")),
        headers: { "Content-Type": 'application/json' }
      )
  end

  def stub_tree_root(resource_id:, repository_id:)
    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/resources/#{resource_id}/tree/root")
      .to_return(
        status: 200,
        body: File.open(Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories', repository_id.to_s, "#{resource_id}_tree_root.json")),
        headers: { "Content-Type": 'application/json' }
      )
  end
end

RSpec.configure do |config|
  config.include AspaceStubbing
end
