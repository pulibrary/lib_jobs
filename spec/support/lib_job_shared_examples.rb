# frozen_string_literal: true

RSpec.shared_examples 'a lib job' do
  let(:job) { described_class.new }

  describe 'category' do
    it 'includes a category on instantiation' do
      expect(job.category).to be_truthy
    end
  end

  describe '#run' do
    it 'returns true' do
      expect(job.run).to be true
    end

    it 'creates a dataset' do
      expect do
        job.run
      end.to change(DataSet, :count).by(1)
    end
  end
end
