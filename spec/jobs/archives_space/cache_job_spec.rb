# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArchivesSpace::CacheJob do
  with_queue_adapter :inline
  it 'creates AR caches of everything it can' do
    stub_aspace_login
    stub_repositories
    # TODO: Fix this bug.
    # This is a bug - it's only caching the first repository right now because
    # repository#top_containers just returns existing cached items if there's
    # any cache at all.
    stub_repository_top_containers(repository_id: 3)
    # stub_location(location_id: 23652)
    stub_location(location_id: 23_640)
    stub_top_containers(ead_id: 'AC001', repository_id: 3)
    stub_resources(repository_id: 3)
    stub_repository(repository_id: 3)
    stub_top_containers(ead_id: 'AC001', repository_id: 4)
    stub_resources(repository_id: 4)
    stub_repository(repository_id: 4)
    stub_container_profiles
    described_class.perform_now

    expect(AbsoluteId::Repository.all.size).to eq 2
    # This number is way too small - it's only one page of one repository.
    # Do we need to cache these even?
    expect(AbsoluteId::TopContainer.all.size).to eq 50
  end
end
