# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::Selector, type: :model do
  let(:first_selector_config) { Rails.application.config.newly_cataloged.selectors[0] }
  let(:second_selector_config) { Rails.application.config.newly_cataloged.selectors[1] }

  let(:first_selector) { described_class.new(selector_config: first_selector_config) }
  let(:second_selector) { described_class.new(selector_config: second_selector_config) }

  it 'can be instantiated' do
    expect(described_class.new(selector_config: first_selector)).to be
  end

  it 'has a name' do
    expect(first_selector.name).to eq('bordelon')
    expect(second_selector.name).to eq('darrington')
  end

  it 'has an array of call numbers ranges' do
    expect(first_selector.call_number_ranges).to match_array([{ class: 'G', low_num: 154.9, high_num: 155.8 },
                                                              { class: 'G', low_num: 156.5, high_num: 156.599 },
                                                              { class: 'GE', low_num: 125, high_num: 125 },
                                                              { class: 'U', low_num: 700, high_num: 799 },
                                                              { class: 'KBR', low_num: 27.2, high_num: 27.4 }])
  end

  it 'has an array of only classes' do
    expect(first_selector.classes).to match_array(['G', 'GE', 'KBR', 'U'])
  end

  it 'has an array of subjects' do
    expect(second_selector.subjects).to match_array(['foreign relations', 'politic', 'policy', 'government'])
  end
end
