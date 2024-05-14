# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "configuration for lc call slips", lc_call_slips: true do
  before do
    string_inquirer = ActiveSupport::StringInquirer.new('production')
    allow(Rails).to receive(:env).and_return(string_inquirer)
  end

  it 'has a configuration' do
    config = Rails.application.config_for(:lc_call_slips, env: "production")
    expect(config.selectors.map { |selector| selector.keys.first }).to include(:donatiello)
  end
end
