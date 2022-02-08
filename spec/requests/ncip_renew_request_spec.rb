# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "NCIPRenew", type: :request do
  describe "ncip-renew" do
    let(:xml_data) { File.new(Rails.root.join('spec', 'fixtures', 'renewitem-b.xml')).read }
    let(:xml_response_data) { File.new(Rails.root.join('spec', 'fixtures', 'renewitemresponse-b.xml')).read }

    it "returns the staff directory" do
      post "/ncip-renew", params: xml_data, headers: { 'HTTP_CONTENT_TYPE' => 'application/xml' }
      expect(response.body.delete("\r\n")).to eq(xml_response_data.delete("\r\n"))
    end
  end
end
