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

  describe "#last_successful_run_time" do
    it "is nil when the job has never run" do
      expect(job.last_successful_run_time).to be_nil
    end

    it "is the report_time of the latest successful run, skipping failed runs and other jobs" do
      DataSet.create!(category: "MyCategory", status: true, report_time: Time.utc(2026, 6, 1))
      DataSet.create!(category: "MyCategory", status: true, report_time: Time.utc(2026, 6, 2))
      DataSet.create!(category: "MyCategory", status: false, report_time: Time.utc(2026, 6, 3))
      DataSet.create!(category: "OtherCategory", status: true, report_time: Time.utc(2026, 6, 4))

      expect(job.last_successful_run_time).to eq(Time.utc(2026, 6, 2))
    end
  end
end
