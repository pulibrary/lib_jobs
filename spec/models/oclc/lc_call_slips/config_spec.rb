# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "configuration for lc call slips", lc_call_slips: true do
  before do
    string_inquirer = ActiveSupport::StringInquirer.new('production')
    allow(Rails).to receive(:env).and_return(string_inquirer)
  end

  let(:config) { Rails.application.config_for(:lc_call_slips, env: "production") }

  it 'has a configuration' do
    expect(config.selectors.map { |selector| selector.keys.first }).to include(:donatiello)
  end

  it 'has only valid configurations in the config file' do
    config.selectors.each do |selector_config|
      selector = Oclc::LcCallSlips::Selector.new(selector_config:)
      expect(selector.valid?).to be true
    end
  end
end
