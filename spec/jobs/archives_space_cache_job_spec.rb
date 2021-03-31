# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArchivesSpaceCacheJob do
  with_queue_adapter :inline
  it 'creates AR caches of everything it can' do
    stub_aspace_login
    stub_repositories
    # TODO: Fix this bug.
    # This is a bug - it's only caching the first repository right now because
    # repository#top_containers just returns existing cached items if there's
    # any cache at all.
    stub_repository_top_containers(repository_id: 3)
    stub_repository(repository_id: 3)
    stub_repository(repository_id: 4)
    stub_container_profiles
    described_class.perform_now

    expect(AbsoluteId::Repository.all.size).to eq 2
    expect(AbsoluteId::ContainerProfile.all.size).to eq 13
    # This number is way too small - it's only one page of one repository.
    # Do we need to cache these even?
    expect(AbsoluteId::TopContainer.all.size).to eq 250
  end
end
