# frozen_string_literal: true
require 'rails_helper'
# require_relative '../../../app/models/aspace_version_control/get_eads_job.rb'

RSpec.describe AspaceVersionControl::Svn do
  let(:status) { double }
  let(:repos) { Rails.application.config.aspace.repos }

  describe "commit_eads_to_svn" do
    context "successful connection to SVN" do
      before do
        allow(status).to receive(:success?).and_return(true)
        allow(Open3).to receive(:capture3)
        allow(Open3).to receive(:capture3).with("svn update tmp/subversion_eads").and_return(["Updating 'subversion_eads':\nAt revision 18345.\n", "", status])
        allow(Open3).to receive(:capture3).with("svn add --force tmp/subversion_eads").and_return(["", "", status])
        repos.each do |_repo, path|
          commit_command = "svn commit tmp/subversion_eads/#{path} -m 'monthly snapshot of ASpace EADs' --username test-username --password test-password"
          allow(Open3).to receive(:capture3)
            .with(commit_command)
            .and_return(["Sending        subversion_eads/ea/EA01.EAD.xml\nTransmitting file data .done\nCommitting transaction...\nCommitted revision 18347.\n", "", status])
        end
      end
      it 'commits to svn' do
        described_class.new.commit_eads_to_svn(path: 'mudd/publicpolicy')
        expect(Open3).to have_received(:capture3).with("svn update tmp/subversion_eads")
        expect(Open3).to have_received(:capture3).with("svn add --force tmp/subversion_eads")
        expect(Open3).to have_received(:capture3).with("svn commit tmp/subversion_eads/mudd/publicpolicy -m 'monthly snapshot of ASpace EADs' --username test-username --password test-password")
      end
    end
    context "failed to connect to SVN" do
      before do
        allow(status).to receive(:success?).and_return(false)
        allow(Open3).to receive(:capture3).with("svn update tmp/subversion_eads").and_return(["Skipped 'tmp/subversion_eads'\n", "svn: E155007: None of the targets are working copies\n", status])
        allow(Open3).to receive(:capture3).with("svn add --force tmp/subversion_eads").and_return(["", "", status])
        repos.each do |_repo, path|
          commit_command = "svn commit tmp/subversion_eads/#{path} -m 'monthly snapshot of ASpace EADs' --username test-username --password test-password"
          allow(Open3).to receive(:capture3)
            .with(commit_command)
            .and_return(["", "svn: E170001: Commit failed (details follow):\nsvn: E170001: Can't get username or password\n", status])
        end
        allow(Rails.logger).to receive(:info)
      end
      it "reports failure" do
        errors = described_class.new.commit_eads_to_svn(path: 'mudd/publicpolicy')
        expect(Rails.logger).to have_received(:info).with(/Skipped/)
        expect(errors).to match_array(["svn: E155007: None of the targets are working copies\n", "SVN Add failed",
                                       "svn: E170001: Commit failed (details follow):\nsvn: E170001: Can't get username or password\n", "Commit failed", "Update failed"])
      end
    end
  end
end
