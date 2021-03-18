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
end

RSpec.configure do |config|
  config.include AspaceStubbing
end
