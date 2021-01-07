# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::Client do
  describe '.build_config' do
    let(:config_attributes) do
      {
        base_uri: "https://archives.university.edu/api",
        username: "admin",
        password: "123456"
      }
    end

    it 'constructs a configuration object' do
      config = described_class.build_config(config_attributes)

      expect(config.base_uri).to eq('https://archives.university.edu/api')
      expect(config.username).to eq('admin')
      expect(config.password).to eq('123456')
    end
  end

  describe '.parse_config' do
    let(:config_file_path) { Rails.root.join('spec', 'fixtures', 'archivesspace_config.yml') }

    it 'constructs a configuration object from a YAML file' do
      client = described_class.parse_config(config_file_path)

      expect(client.config.base_uri).to eq('https://archives.university.edu/api')
      expect(client.config.username).to eq('admin')
      expect(client.config.password).to eq('123456')
    end
  end
end
