# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LibJob, type: :model do
  let(:job) { described_class.new(category: "MyCategory") }

  describe "#run" do
    it "throws an exception" do
      expect { job.run }.to raise_error(NoMethodError)
    end

    it "creates a dataset for a subclass" do
      class MyClass < LibJob
        def handle(data_set:)
          data_set
        end
      end
      expect { MyClass.new(category: "cat").run }.to change { DataSet.count }.by(1)
    end
  end
end
