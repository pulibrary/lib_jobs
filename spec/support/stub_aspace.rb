# frozen_string_literal: true
module AspaceStubbing
  def stub_aspace_login
    stub_request(:post, "https://aspace.test.org/staff/api/users/test/login?password=password").to_return(status: 200, body: { session: "1" }.to_json, headers: { "Content-Type": "application/json" })
  end

  def stub_container_profiles
    stub_request(:get, "https://aspace.test.org/staff/api/container_profiles?page=1&page_size=100000")
      .to_return(
        status: 200,
        body: File.open(Rails.root.join("spec", "fixtures", "archives_space", "container_profiles.json")),
        headers: { "Content-Type": "application/json" }
      )
  end

  def stub_locations
    stub_request(:get, "https://aspace.test.org/staff/api/locations?page=1&page_size=100000")
      .to_return(
        status: 200,
        body: File.open(Rails.root.join("spec", "fixtures", "archives_space", "locations.json")),
        headers: { "Content-Type": "application/json" }
      )
  end

  # @note Currently only stubs Repository 4, univarchives, because that's what
  # we're using in testing.
  def stub_repository
    stub_request(:get, "https://aspace.test.org/staff/api/repositories/4")
      .to_return(
        status: 200,
        body: File.open(Rails.root.join("spec", "fixtures", "archives_space", "repository.json")),
        headers: { "Content-Type": "application/json" }
      )
  end

  def stub_repository_top_containers(repository_id:)
    stub_request(:get, "https://aspace.test.org/staff/api/repositories/#{repository_id}/top_containers?page=1&page_size=100000&resolve[]=container_locations")
      .to_return(
        status: 200,
        body: File.open(Rails.root.join("spec", "fixtures", "archives_space", "top_containers_#{repository_id}_page1.json")),
        headers: { "Content-Type": "application/json" }
      )
  end
end

RSpec.configure do |config|
  config.include AspaceStubbing
end
