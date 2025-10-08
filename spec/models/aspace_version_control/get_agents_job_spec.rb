# frozen_string_literal: true
require 'rails_helper'
require_relative '../../../app/models/aspace_version_control/get_agents_job.rb'

RSpec.describe AspaceVersionControl::GetAgentsJob do
  let(:agents_job) { described_class.new }
  let(:mock_client) { double('ArchivesSpace::Client') }
  let(:mock_config) { double('ArchivesSpace::Configuration') }

  # Sample CPF XML response
  let(:cpf_xml_body) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <eac-cpf xmlns="urn:isbn:1-931666-33-4">
        <control>
          <recordId>SMITHHENRYBRADFORD</recordId>
          <maintenanceStatus>revised</maintenanceStatus>
        </control>
        <cpfDescription>
          <identity>
            <entityId>SMITHHENRYBRADFORD</entityId>
            <entityType>person</entityType>
            <nameEntry>
              <part localType="surname">Smith</part>
              <part localType="forename">Henry Bradford</part>
              <authorizedForm>local</authorizedForm>
            </nameEntry>
          </identity>
        </cpfDescription>
      </eac-cpf>
    XML
  end

  let(:cpf_response) do
    double('ArchivesSpace::Response', body: cpf_xml_body)
  end

  let(:agent_ids_response) do
    double('ArchivesSpace::Response', parsed: [13, 14, 15])
  end

  before do
    # Environment variable mocks
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("ASPACE_URL").and_return("https://aspace-staging.princeton.edu/staff/api")
    allow(ENV).to receive(:[]).with("ASPACE_USER").and_return("testuser")
    allow(ENV).to receive(:[]).with("ASPACE_PASSWORD").and_return("testpassword")

    # ArchivesSpace client mocks
    allow(ArchivesSpace::Configuration).to receive(:new).and_return(mock_config)
    allow(ArchivesSpace::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:login).and_return(mock_client)
  end

  describe "#initialize" do
    it "sets up the job with correct category" do
      expect(agents_job.instance_variable_get(:@errors)).to eq([])
    end
  end

  describe "#aspace_config" do
    it "creates a configuration with environment variables" do
      expect(ArchivesSpace::Configuration).to receive(:new).with({
                                                                   base_uri: "https://aspace-staging.princeton.edu/staff/api",
                                                                   username: "testuser",
                                                                   password: "testpassword",
                                                                   throttle: 0,
                                                                   verify_ssl: false
                                                                 })
      agents_job.aspace_config
    end

    context "when environment variables are missing" do
      before do
        allow(ENV).to receive(:[]).with("ASPACE_URL").and_return(nil)
      end

      it "raises an error" do
        expect { agents_job.aspace_config }.to raise_error("Missing required environment variables: ASPACE_URL, ASPACE_USER, or ASPACE_PASSWORD")
      end
    end
  end

  describe "#aspace_login" do
    it "establishes connection and returns client" do
      expect(agents_job.aspace_login).to eq(mock_client)
    end

    context "when connection fails" do
      before do
        allow(mock_client).to receive(:login).and_raise(StandardError.new("Connection failed"))
        allow(Rails.logger).to receive(:error)
      end

      it "logs error and re-raises" do
        expect { agents_job.aspace_login }.to raise_error("Connection failed")
        expect(Rails.logger).to have_received(:error).with("Failed to connect to ArchivesSpace: Connection failed")
      end
    end
  end

  describe "agent listing methods" do
    before do
      agents_job.instance_variable_set(:@client, mock_client)
    end

    describe "#list_family_agents" do
      before do
        allow(mock_client).to receive(:get).with("agents/families", { query: { all_ids: true } }).and_return(agent_ids_response)
      end

      it "returns parsed list of family agent IDs" do
        expect(agents_job.list_family_agents).to eq([13, 14, 15])
      end
    end

    describe "#list_corporate_entities_agents" do
      before do
        allow(mock_client).to receive(:get).with("agents/corporate_entities", { query: { all_ids: true } }).and_return(agent_ids_response)
      end

      it "returns parsed list of corporate entity agent IDs" do
        expect(agents_job.list_corporate_entities_agents).to eq([13, 14, 15])
      end
    end

    describe "#list_person_agents" do
      before do
        allow(mock_client).to receive(:get).with("agents/people", { query: { all_ids: true } }).and_return(agent_ids_response)
      end

      it "returns parsed list of person agent IDs" do
        expect(agents_job.list_person_agents).to eq([13, 14, 15])
      end
    end
  end

  describe "#get_archival_context_xml" do
    before do
      agents_job.instance_variable_set(:@client, mock_client)
      allow(mock_client).to receive(:get).with("/repositories/1/archival_contexts/people/13.xml").and_return(cpf_response)
    end

    it "returns XML content and filename for person agent" do
      result = agents_job.get_archival_context_xml(13, 'people')

      expect(result[:xml_content]).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(result[:xml_content]).to include('<part localType="surname">Smith</part>')
      expect(result[:xml_content]).to include('<part localType="forename">Henry Bradford</part>')
      expect(result[:xml_content]).to include('<authorizedForm>local</authorizedForm>')
      expect(result[:filename]).to eq('SMITH_HENRYBRADFORD_people_13.CPF.xml')
    end

    it "makes correct API call for different agent types" do
      expect(mock_client).to receive(:get).with("/repositories/1/archival_contexts/families/13.xml").and_return(cpf_response)
      agents_job.get_archival_context_xml(13, 'families')
    end
  end

  describe "convenience methods" do
    before do
      agents_job.instance_variable_set(:@client, mock_client)
      allow(mock_client).to receive(:get).and_return(cpf_response)
    end

    describe "#get_person_archival_context_xml" do
      it "calls generic method with people type" do
        expect(agents_job).to receive(:get_archival_context_xml).with(13, 'people')
        agents_job.get_person_archival_context_xml(13)
      end
    end

    describe "#get_family_archival_context_xml" do
      it "calls generic method with families type" do
        expect(agents_job).to receive(:get_archival_context_xml).with(13, 'families')
        agents_job.get_family_archival_context_xml(13)
      end
    end

    describe "#get_corporate_entity_archival_context_xml" do
      it "calls generic method with corporate_entities type" do
        expect(agents_job).to receive(:get_archival_context_xml).with(13, 'corporate_entities')
        agents_job.get_corporate_entity_archival_context_xml(13)
      end
    end
  end

  describe "#write_cpf_to_file" do
    let(:temp_dir) { 'tmp/test_agents' }

    before do
      FileUtils.mkdir_p(temp_dir)
      agents_job.instance_variable_set(:@client, mock_client)
      allow(mock_client).to receive(:get).and_return(cpf_response)
      allow(Rails.logger).to receive(:info)
    end

    after do
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end

    it "writes CPF XML to file with correct filename" do
      filename = agents_job.write_cpf_to_file(temp_dir, 13, 'people')

      expect(File.exist?("#{temp_dir}/SMITH_HENRYBRADFORD_people_13.CPF.xml")).to be true
      expect(filename).to eq('SMITH_HENRYBRADFORD_people_13.CPF.xml')

      file_content = File.read("#{temp_dir}/SMITH_HENRYBRADFORD_people_13.CPF.xml")
      expect(file_content).to include('<entityId>SMITHHENRYBRADFORD</entityId>')
    end

    it "logs processing information" do
      agents_job.write_cpf_to_file(temp_dir, 13, 'people')

      expect(Rails.logger).to have_received(:info).with("Processing CPF for people/13")
      expect(Rails.logger).to have_received(:info).with("Wrote CPF XML to #{temp_dir}/SMITH_HENRYBRADFORD_people_13.CPF.xml")
    end

    context "when processing fails" do
      before do
        allow(agents_job).to receive(:get_archival_context_xml).and_raise(StandardError.new("API error"))
        allow(Rails.logger).to receive(:info)
      end

      it "logs the error and continues" do
        expect { agents_job.write_cpf_to_file(temp_dir, 13, 'people') }.not_to raise_error
        expect(agents_job.instance_variable_get(:@errors)).to include("Unable to process CPF for people/13: API error")
      end
    end
  end

  describe "#process_all_cpf_files" do
    let(:temp_dir) { 'tmp/test_processing' }

    before do
      FileUtils.mkdir_p(temp_dir)
      agents_job.instance_variable_set(:@client, mock_client)
      allow(mock_client).to receive(:get).with("agents/people", { query: { all_ids: true } }).and_return(agent_ids_response)
      allow(mock_client).to receive(:get).with("/repositories/1/archival_contexts/people/13.xml").and_return(cpf_response)
      allow(mock_client).to receive(:get).with("/repositories/1/archival_contexts/people/14.xml").and_return(cpf_response)
      allow(mock_client).to receive(:get).with("/repositories/1/archival_contexts/people/15.xml").and_return(cpf_response)
      allow(Rails.logger).to receive(:info)
      allow(File).to receive(:write).and_call_original
    end

    after do
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end

    it "processes all agents of specified type" do
      processed_count = agents_job.process_all_cpf_files('people', temp_dir, chunk_size: 2, start_from: 0)

      expect(processed_count).to eq(3)
      expect(Rails.logger).to have_received(:info).with("Processing 3 people agents for CPF files (starting from 0)")
    end

    it "creates checkpoint file during processing" do
      agents_job.process_all_cpf_files('people', temp_dir, chunk_size: 2, start_from: 0)

      # Should create checkpoint after processing 2 agents (chunk_size: 2)
      expect(File).to have_received(:write).with("#{temp_dir}/people_checkpoint.txt", 2)
    end

    it "cleans up checkpoint file on completion" do
      allow(File).to receive(:delete)

      agents_job.process_all_cpf_files('people', temp_dir, chunk_size: 2, start_from: 0)

      expect(File).to have_received(:delete).with("#{temp_dir}/people_checkpoint.txt")
    end

    context "when resuming from checkpoint" do
      before do
        File.write("#{temp_dir}/people_checkpoint.txt", "1")
      end

      it "resumes from checkpoint position" do
        processed_count = agents_job.process_all_cpf_files('people', temp_dir, chunk_size: 2, start_from: 0)

        expect(Rails.logger).to have_received(:info).with("Resuming from checkpoint: 1")
        expect(processed_count).to eq(2) # Only processes remaining agents (14, 15)
      end
    end

    context "with unknown agent type" do
      it "raises an error" do
        expect { agents_job.process_all_cpf_files('croutons', temp_dir) }.to raise_error("Unknown agent type: croutons")
      end
    end
  end

  describe "convenience processing methods" do
    let(:temp_dir) { 'tmp/test_convenience' }

    before do
      FileUtils.mkdir_p(temp_dir)
    end

    after do
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end

    describe "#process_all_person_cpf_files" do
      it "calls generic method with people type" do
        expect(agents_job).to receive(:process_all_cpf_files).with('people', temp_dir, chunk_size: 500, start_from: 0)
        agents_job.process_all_person_cpf_files(temp_dir)
      end
    end

    describe "#process_all_family_cpf_files" do
      it "calls generic method with families type" do
        expect(agents_job).to receive(:process_all_cpf_files).with('families', temp_dir, chunk_size: 500, start_from: 0)
        agents_job.process_all_family_cpf_files(temp_dir)
      end
    end

    describe "#process_all_corporate_entity_cpf_files" do
      it "calls generic method with corporate_entities type" do
        expect(agents_job).to receive(:process_all_cpf_files).with('corporate_entities', temp_dir, chunk_size: 500, start_from: 0)
        agents_job.process_all_corporate_entity_cpf_files(temp_dir)
      end
    end
  end

  describe "#generate_cpf_filename" do
    let(:doc_with_name_parts) do
      Nokogiri::XML(cpf_xml_body)
    end

    let(:doc_without_names) do
      Nokogiri::XML(<<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <eac-cpf xmlns="urn:isbn:1-931666-33-4">
          <control>
            <recordId>TESTRECORD123</recordId>
          </control>
          <cpfDescription>
            <identity>
              <entityId>TESTENTITY456</entityId>
            </identity>
          </cpfDescription>
        </eac-cpf>
      XML
    end

    it "generates filename from surname and forename" do
      filename = agents_job.send(:generate_cpf_filename, doc_with_name_parts, 13, 'people')
      expect(filename).to eq('SMITH_HENRYBRADFORD_people_13')
    end

    it "falls back to entityId when name parts not found" do
      filename = agents_job.send(:generate_cpf_filename, doc_without_names, 13, 'families')
      expect(filename).to eq('families_13')
    end

    it "falls back to agent_id when no identifiers found" do
      empty_doc = Nokogiri::XML('<root></root>')
      filename = agents_job.send(:generate_cpf_filename, empty_doc, 13, 'people')
      expect(filename).to eq('people_13')
    end
  end

  describe "#handle" do
    let(:data_set) { DataSet.new(category: "Agents_export") }

    before do
      allow(agents_job).to receive(:aspace_login).and_return(mock_client)
    end

    it "processes the data set and sets report time" do
      result = agents_job.handle(data_set: data_set)

      expect(result.data).to eq("Agents successfully exported.")
      expect(result.report_time).to be_within(1.second).of(Time.zone.now)
    end
  end

  describe "#report" do
    context "when no errors occurred" do
      it "returns success message" do
        expect(agents_job.report).to eq("Agents successfully exported.")
      end
    end

    context "when errors occurred" do
      before do
        agents_job.instance_variable_set(:@errors, ["Error 1", "Error 2"])
      end

      it "returns joined error messages" do
        expect(agents_job.report).to eq("Error 1, Error 2")
      end
    end
  end
end
