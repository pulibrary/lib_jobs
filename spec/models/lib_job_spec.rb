# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LibJob, type: :model do
  let(:job) { described_class.new }

  describe "#run" do
    let(:my_subclass) do
      Class.new(LibJob) do
        def category = 'MyCategory'
      end
    end
    it "throws an exception" do
      expect { my_subclass.run }.to raise_error(NoMethodError)
    end

    it "creates a dataset for a subclass" do
      class MyClass < LibJob
        def category = 'cat'

        def handle(data_set:)
          data_set
        end
      end
      expect { MyClass.new.run }.to change { DataSet.count }.by(1)
    end
  end

  describe "#last_successful_run_time" do
    let(:my_subclass) do
      Class.new(LibJob) do
        def category = 'MyCategory'
      end
    end
    it "is nil when the job has never run" do
      expect(my_subclass.new.last_successful_run_time).to be_nil
    end

    it "is the report_time of the latest successful run, skipping failed runs and other jobs" do
      DataSet.create!(category: "MyCategory", status: true, report_time: Time.utc(2026, 6, 1))
      DataSet.create!(category: "MyCategory", status: true, report_time: Time.utc(2026, 6, 2))
      DataSet.create!(category: "MyCategory", status: false, report_time: Time.utc(2026, 6, 3))
      DataSet.create!(category: "OtherCategory", status: true, report_time: Time.utc(2026, 6, 4))

      expect(my_subclass.new.last_successful_run_time).to eq(Time.utc(2026, 6, 2))
    end
  end

  describe '#category' do
    it 'throws an exception' do
      expect { job.category }.to raise_error(NotImplementedError)
    end
  end
end
