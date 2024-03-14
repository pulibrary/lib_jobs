# frozen_string_literal: true

RSpec.shared_examples 'a lib job' do
  let(:job) { described_class.new }

  describe 'category' do
    it 'includes a category on instantiation' do
      expect(job.category).to be_truthy
    end
  end
end
