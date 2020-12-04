# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataSet, type: :model do
  let(:data_set) { described_class.new }

  it 'has to the expected attributes' do
    expect(data_set.attributes).to eq({ "category" => nil, "created_at" => nil, "data" => nil, "data_file" => nil, "id" => nil, "report_time" => nil, "updated_at" => nil })
  end
end
