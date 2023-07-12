# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaSubmitCollection::AlmaSubmitCollectionJob, type: :model do
  describe "#run" do
    it "runs" do
      described_class.new(category: 'mouse').run
    end

    it "logs the number of records processed" do
      data_set = described_class.new(category: 'mouse').run
      data_last = DataSet.last
      expect(data_last.data).to eq "20 records processed."
    end
  end
end
