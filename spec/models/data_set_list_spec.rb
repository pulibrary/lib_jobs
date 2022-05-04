# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataSetList, type: :model do
  let!(:data_set1) { DataSet.create(category: "abc") }
  let(:data_set_list) { described_class.new([data_set1]) }

  it 'Can list all the available categories' do
    FactoryBot.create :data_set, category: 'abc'
    FactoryBot.create :data_set, category: '123'
    FactoryBot.create :data_set, category: 'def'
    expect(data_set_list.categories).to contain_exactly("abc", "123", "def")
  end

  it 'returns the list members' do
    data_set_list.each do |data_set|
      expect(data_set).to eq(data_set1)
    end
  end
end
