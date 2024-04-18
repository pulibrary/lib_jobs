# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaRenew::RenewFile, type: :model, file_download: true do
  let(:temp_file) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:renew_file) { described_class.new(temp_file:) }

  it "can be instantiated" do
    expect(described_class.new(temp_file:)).to be
  end

  it "can access the temp_file" do
    expect(renew_file.temp_file).to eq(temp_file)
  end

  describe "#process" do
    before do
      allow(Tempfile).to receive(:new).and_return(temp_file)
    end

    around do |example|
      temp_file.write(File.open(File.join('spec', 'fixtures', 'renew.csv')).read)
      temp_file.rewind
      example.run
    end

    it "can be processed" do
      expect(described_class.new(temp_file:).process).to be
    end

    it "returns an array" do
      expect(renew_file.process).to be_instance_of(Array)
    end

    it "has Items in the array" do
      expect(renew_file.process.first).to be_instance_of(AlmaRenew::Item)
    end
  end
end
