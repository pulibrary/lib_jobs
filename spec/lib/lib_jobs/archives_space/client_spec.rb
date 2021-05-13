# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::Client do
  subject(:client) { described_class.source }

  let(:repo_code) { 'mss' }

  describe '.source' do
    let(:config_properties) do
      {
        'archivesspace' => {
          'source' => {
            base_uri: "https://archives-readonly.university.edu/api",
            username: "admin",
            password: "123456"
          }
        }
      }
    end
    let(:client) { described_class.source }

    before do
      allow(LibJobs).to receive(:config).and_return(config_properties)
    end

    it 'constructs a client for an ArchivesSpace source repository' do
      expect(client.base_uri).to eq('https://archives-readonly.university.edu/api')
    end
  end

  describe '.sync' do
    let(:config_properties) do
      {
        'archivesspace' => {
          'sync' => {
            base_uri: "https://archives.university.edu/api",
            username: "admin",
            password: "123456"
          }
        }
      }
    end
    let(:client) { described_class.sync }

    before do
      allow(LibJobs).to receive(:config).and_return(config_properties)
    end

    it 'constructs a client for an ArchivesSpace installation used for synchronizing TopContainer and Location Records' do
      expect(client.base_uri).to eq('https://archives.university.edu/api')
    end
  end

  describe '#select_repositories_by' do
    before do
      stub_repositories
      stub_aspace_login
    end

    it 'selects repositories by the repository code' do
      selected = client.select_repositories_by(repo_code: repo_code)

      expect(selected).to be_an(Array)
      expect(selected.length).to eq(1)
      expect(selected.first.repo_code).to eq(repo_code)
    end
  end
end
