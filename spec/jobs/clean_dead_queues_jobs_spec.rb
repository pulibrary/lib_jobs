# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CleanDeadQueuesJob do
  let(:sidekiq_dead_set) { instance_double(Sidekiq::DeadSet) }

  describe '.perform' do
    before do
      allow(sidekiq_dead_set).to receive(:clear)
      stub_const("Sidekiq::DeadSet", sidekiq_dead_set)

      described_class.perform_now
    end

    it 'cleans all dead queues' do
      expect(sidekiq_dead_set).to have_received(:clear)
    end
  end
end
