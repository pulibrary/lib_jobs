# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AspaceSvn::GetEadsJob do
  describe "#run" do
    before do
      stub_request(:post, %r{\Ahttps://aspace-staging\.princeton\.edu/staff/api/users/}).and_return(
        status: 200, body: "{'session': 123}"
      )
      stub_request(:get, %r{\Ahttps://aspace-staging\.princeton\.edu/staff/api/repositories/\d+/resources\?all_ids=true}).and_return(
        status: 200, body: "[1234,5678]\n",
        headers: { "content-type" => "application/json" }
      )
      stub_request(:get, %r{\Ahttps://aspace-staging\.princeton\.edu/staff/api/repositories/\d+/resource_descriptions}).and_return(
        status: 200, body: "<xml><eadid>My_ID</eadid></xml>"
      )
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
      Dir.glob(Rails.root.join('tmp', 'eads', '*')).each { |directory| FileUtils.rm_r(directory) }
      example.run
      Dir.glob(Rails.root.join('tmp', 'eads', '*')).each { |directory| FileUtils.rm_r(directory) }
    end
    it "creates directories for all relevant ead repos" do
      described_class.new.run
      expect(File).to exist(Rails.root.join('tmp', 'eads', 'mudd', 'publicpolicy'))
      expect(File).to exist(Rails.root.join('tmp', 'eads', 'mudd', 'univarchives'))
      expect(File).to exist(Rails.root.join('tmp', 'eads', 'mss'))
      expect(File).to exist(Rails.root.join('tmp', 'eads', 'rarebooks'))
      expect(File).to exist(Rails.root.join('tmp', 'eads', 'cotsen'))
      expect(File).to exist(Rails.root.join('tmp', 'eads', 'lae'))
      expect(File).to exist(Rails.root.join('tmp', 'eads', 'eng'))
      expect(File).to exist(Rails.root.join('tmp', 'eads', 'selectors'))
      expect(File).to exist(Rails.root.join('tmp', 'eads', 'ga'))
      expect(File).to exist(Rails.root.join('tmp', 'eads', 'ea'))
    end
  end
  describe "report" do
    it "reports success" do
      expect(described_class.new.report).to eq "EADs successfully exported."
    end
  end
end
