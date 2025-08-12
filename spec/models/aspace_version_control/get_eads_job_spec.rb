# frozen_string_literal: true
require 'rails_helper'
require_relative '../../../app/models/aspace_version_control/get_eads_job.rb'

RSpec.describe AspaceVersionControl::GetEadsJob do
  let(:status) { double }
  let(:repos) { Rails.application.config.aspace.repos }
  let(:git_lab_repo) { Git.init('tmp/gitlab_eads') }

  before do
    # GitLab mocks
    allow(Git).to receive(:clone).and_return(git_lab_repo)
    allow(git_lab_repo).to receive(:pull).and_return("Already up to date.")
    allow(git_lab_repo).to receive(:add).and_return("")
    allow(git_lab_repo).to receive(:commit).and_return("[main b1b385c] monthly snapshot of ASpace EADs\n 1 file changed, 0 insertions(+), 0 deletions(-)\n create mode 100644 testing")
    allow(git_lab_repo).to receive(:push).and_return(nil)
    # end GitLab mocks
  end
  describe "#run" do
    before do
      stub_request(:post, %r{\Ahttps://aspace-staging\.princeton\.edu/staff/api/users/})
        .and_return(
        status: 200, body: "{'session': 123}"
      )
      stub_request(:get, %r{\Ahttps://aspace-staging\.princeton\.edu/staff/api/repositories/\d+/resources\?all_ids=true})
        .and_return(
        status: 200, body: "[1234,5678]\n",
        headers: { "content-type" => "application/json" }
      )
      stub_request(:get, %r{\Ahttps://aspace-staging\.princeton\.edu/staff/api/repositories/\d+/resource_descriptions})
        .and_return(
        status: 200, body: File.new(file_fixture('ead_from_aspace.xml'))
      )
      allow(ENV)
        .to receive(:[])
      allow(ENV)
        .to receive(:[])
        .with("ASPACE_URL")
        .and_return("https://aspace-staging.princeton.edu/staff/api")
      allow(ENV)
        .to receive(:[])
        .with("ASPACE_USER")
        .and_return("netid")
      allow(ENV)
        .to receive(:[])
        .with("ASPACE_PASSWORD")
        .and_return("password")
    end
    around do |example|
      Rails.root.glob('tmp/gitlab_eads/*').each { |directory| FileUtils.rm_r(directory) }
      example.run
      Rails.root.glob('tmp/gitlab_eads/*').each { |directory| FileUtils.rm_r(directory) }
    end
    it "creates directories for all relevant ead repos" do
      described_class.new.run
      expect(File).to exist(Rails.root.join('tmp', 'gitlab_eads', 'mudd', 'publicpolicy'))
      expect(File).to exist(Rails.root.join('tmp', 'gitlab_eads', 'rarebooks'))
      expect(File).to exist(Rails.root.join('tmp', 'gitlab_eads', 'ga'))
      expect(File).to exist(Rails.root.join('tmp', 'gitlab_eads', 'ea'))
    end
    it "works even if the gitlab_eads folder has not yet been initialized as a git repo" do
      allow(Git).to receive(:clone).and_raise Git::FailedError, Git::CommandLineResult.new("clone", double(), "", "gitlab_eads already exists and is not an empty directory.")
      allow(Git).to receive(:open).and_raise ArgumentError, "gitlab_eads is not in a git working tree"
      described_class.new.run
      expect(File).to exist(Rails.root.join('tmp', 'gitlab_eads', 'mudd', 'publicpolicy'))
      expect(File).to exist(Rails.root.join('tmp', 'gitlab_eads', 'rarebooks'))
      expect(File).to exist(Rails.root.join('tmp', 'gitlab_eads', 'ga'))
      expect(File).to exist(Rails.root.join('tmp', 'gitlab_eads', 'ea'))
    end
    it "gets filename from the eadid element in the EAD xml api response" do
      described_class.new.run
      expect(File).to exist(Rails.root.join('tmp', 'gitlab_eads', 'mudd', 'publicpolicy', 'MyEadID.EAD.xml'))
    end
    it "puts the EAD xml file with corrected namespace into the file" do
      described_class.new.run
      expect(FileUtils.identical?(Rails.root.join('tmp', 'gitlab_eads', 'mudd', 'publicpolicy', 'MyEadID.EAD.xml'),
                                  file_fixture('ead_corrected.xml'))).to be true
    end
    describe "report" do
      it "reports success" do
        out = described_class.new
        out.handle(data_set: DataSet.new(category: "EAD_export"))
        expect(out.report).to eq "EADs successfully exported."
      end
    end
    describe '#get_resource_ids_for_repo' do
      context 'with a timeout error' do
        let(:eads_job) { described_class.new }
        let(:aspace_client) { eads_job.aspace_login }
        before do
          allow(Rails.logger).to receive(:warn).and_call_original
          allow(ArchivesSpace::Client).to receive(:new).and_return(aspace_client)
          allow(aspace_client).to receive(:get).and_raise(Net::ReadTimeout)
          allow(Rails.logger).to receive(:warn).and_call_original
          allow(Rails.logger).to receive(:error).and_call_original
        end

        it 'retries' do
          expect do
            eads_job.get_resource_ids_for_repo(3)
          end.not_to raise_error
          expect(Rails.logger).to have_received(:warn).exactly(3).times
          expect(Rails.logger).to have_received(:error).once
        end
      end
    end
    describe "write_eads_to_file" do
      context "with XML syntax errors" do
        let(:dir) { "tmp/gitlab_eads/rarebooks" }
        let(:repo) { 6 }
        let(:id) { 1234 }
        before do
          # Raising the error within the method to simulate a parsing failure
          allow(Rails.logger).to receive(:info).and_call_original
          allow(Rails.logger).to receive(:info).with("Now processing 6/1234").and_raise(Nokogiri::XML::SyntaxError)
        end
        it "records the error and completes the job" do
          out = described_class.new
          out.handle(data_set: DataSet.new(category: "EAD_export"))
          expect(out.report).to include "Unable to process XML for record 6/1234, please check the source XML for errors"

          # Ensure the process continues after logging exception
          expect(FileUtils.identical?(Rails.root.join('tmp', 'gitlab_eads', 'ea', 'MyEadID.EAD.xml'),
                                      file_fixture('ead_corrected.xml'))).to be true
        end
      end
    end
  end
end
