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

  it 'has an email' do
    expect(first_selector.email).to eq('bordelon@princeton.edu')
    expect(second_selector.email).to eq('jdarring@princeton.edu')
  end

  it 'has an array of call numbers ranges' do
    expect(first_selector.call_number_ranges).to match_array([{ class: "G", low_num: 154.9, high_num: 155.8 },
                                                              { class: "G", low_num: 156.5, high_num: 156.599 }, { class: "GE", low_num: 125, high_num: 125 },
                                                              { class: "GE", low_num: 140, high_num: 160 }, { class: "GE", low_num: 170, high_num: 190 },
                                                              { class: "GE", low_num: 195, high_num: 199 }, { class: "GV", low_num: 350, high_num: 350 },
                                                              { class: "GV", low_num: 716, high_num: 716 }, { class: "H", low_num: 0, high_num: 99_999 },
                                                              { class: "HA", low_num: 0, high_num: 99_999 }, { class: "HB", low_num: 0, high_num: 99_999 },
                                                              { class: "HC", low_num: 0, high_num: 99_999 }, { class: "HD", low_num: 0, high_num: 99_999 },
                                                              { class: "HE", low_num: 0, high_num: 99_999 }, { class: "HF", low_num: 0, high_num: 99_999 },
                                                              { class: "HG", low_num: 0, high_num: 99_999 }, { class: "HJ", low_num: 0, high_num: 99_999 },
                                                              { class: "HQ", low_num: 444, high_num: 445 }, { class: "HQ", low_num: 1240, high_num: 1240.5 },
                                                              { class: "HQ", low_num: 1381, high_num: 1381 }, { class: "HT", low_num: 388, high_num: 388 },
                                                              { class: "HX", low_num: 0, high_num: 99_999 }, { class: "LC", low_num: 65, high_num: 245 },
                                                              { class: "ML", low_num: 3790, high_num: 3792 }, { class: "N", low_num: 8600, high_num: 8675 },
                                                              { class: "NX", low_num: 634, high_num: 634 }, { class: "NX", low_num: 700, high_num: 750 },
                                                              { class: "RA", low_num: 407, high_num: 416.5 }, { class: "S", low_num: 401, high_num: 401 },
                                                              { class: "S", low_num: 560, high_num: 565.88 }, { class: "SH", low_num: 334, high_num: 334 },
                                                              { class: "TX", low_num: 901, high_num: 946.5 }, { class: "TX", low_num: 950, high_num: 953 }])
  end

  it 'has an array of only classes' do
    expect(first_selector.classes).to match_array(["G", "GE", "GV", "H", "HA", "HB", "HC", "HD", "HE",
                                                   "HF", "HG", "HJ", "HQ", "HT", "HX", "LC", "ML", "N", "NX", "RA", "S", "SH", "TX"])
  end

  it 'has an array of subjects' do
    expect(second_selector.subjects).to match_array(['foreign relations', 'politic', 'policy', 'government'])
  end
end
