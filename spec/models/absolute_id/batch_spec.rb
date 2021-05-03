# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteId::Batch, type: :model do
  subject(:batch) do
    described_class.new(
      user: user,
      absolute_ids: [
        absolute_id1,
        absolute_id2
      ]
    )
  end

  let(:user) { create(:user) }
  let(:absolute_id1) { create(:absolute_id, value: '32101103191142', check_digit: '2', index: 0) }
  let(:absolute_id2) { create(:absolute_id, value: '32101103191159', check_digit: '9', index: 1) }

  before do
    batch.save
    batch.reload
  end

  describe '#synchronize_status' do
    it 'accesses the synchronization status' do
      expect(batch.synchronize_status).to eq('never synchronized')
    end

    context '' do
      let(:absolute_id1) { create(:absolute_id, value: '32101103191142', check_digit: '2', index: 0, synchronize_status: 'unsynchronized') }

      it 'accesses the synchronization status' do
        expect(batch.synchronize_status).to eq('never synchronized')
      end
    end

    context '' do
      let(:absolute_id1) { create(:absolute_id, value: '32101103191142', check_digit: '2', index: 0, synchronize_status: 'synchronizing') }

      it 'accesses the synchronization status' do
        expect(batch.synchronize_status).to eq('synchronizing')
      end
    end

    context '' do
      let(:absolute_id1) { create(:absolute_id, value: '32101103191142', check_digit: '2', index: 0, synchronize_status: 'synchronization failed') }

      it 'accesses the synchronization status' do
        expect(batch.synchronize_status).to eq('synchronization failed')
      end
    end
  end

  describe '#as_json' do
    it 'serializes the attributes as a JSON Object' do
      expect(batch.as_json).to be_a(Hash)
      expect(batch.as_json[:absolute_ids]).to be_an(Array)
      expect(batch.as_json[:id]).to eq(batch.id)
      expect(batch.as_json[:label]).to eq(batch.label)

      expect(batch.as_json[:absolute_ids].first).to include(
        barcode: {
          check_digit: nil,
          digits: [3, 2, 1, 0, 1, 1, 0, 3, 1, 9, 1, 1, 4],
          integer: 3_210_110_319_114,
          valid: false,
          value: "32101103191142"
        },
        container: {},
        container_profile: {},
        id: 0,
        label: nil,
        location: {},
        repository: {},
        resource: {},
        size: nil,
        synchronize_status: "never synchronized",
        synchronized_at: nil
      )
      expect(batch.as_json[:absolute_ids].last).to include(
        barcode: {
          check_digit: nil,
          digits: [3, 2, 1, 0, 1, 1, 0, 3, 1, 9, 1, 1, 5],
          integer: 3_210_110_319_115,
          valid: false,
          value: "32101103191159"
        },
        container: {},
        container_profile: {},
        label: nil,
        location: {},
        repository: {},
        resource: {},
        size: nil,
        synchronize_status: "never synchronized",
        synchronized_at: nil
      )
    end
  end

  describe '#data_table' do
    it 'builds a data table structure' do
      expect(batch.data_table).to be_an(AbsoluteId::Batch::TablePresenter)
      expect(batch.data_table.class.columns).to be_an(Array)
      expect(batch.data_table.class.columns).to eq(
        [
          { name: 'label', display_name: 'Identifier', align: 'left', sortable: true },
          { name: 'barcode', display_name: 'Barcode', align: 'left', sortable: true, ascending: 'undefined' },
          { name: 'location', display_name: 'Location', align: 'left', sortable: false },
          { name: 'container_profile', display_name: 'Container Profile', align: 'left', sortable: false },
          { name: 'repository', display_name: 'Repository', align: 'left', sortable: false },
          { name: 'resource', display_name: 'ASpace Resource', align: 'left', sortable: false },
          { name: 'container', display_name: 'ASpace Container', align: 'left', sortable: false },
          { name: 'user', display_name: 'User', align: 'left', sortable: false },
          { name: 'status', display_name: 'Synchronization', align: 'left', sortable: false, datatype: 'constant' }
        ]
      )
      expect(batch.data_table.rows).to be_an(Array)
      expect(batch.data_table.rows).to eq(
        [
          {
            label: nil,
            barcode: "32101103191142",
            location: { link: nil, value: nil },
            container_profile: { link: nil, value: nil },
            repository: { link: nil, value: nil },
            resource: { link: nil, value: nil },
            container: { link: nil, value: nil },
            user: "user@locahost.localdomain",
            status: { value: "never synchronized", color: "blue" },
            synchronized_at: "Never"
          },
          {
            label: nil,
            barcode: "32101103191159",
            location: { link: nil, value: nil },
            container_profile: { link: nil, value: nil },
            repository: { link: nil, value: nil },
            resource: { link: nil, value: nil },
            container: { link: nil, value: nil },
            user: "user@locahost.localdomain",
            status: { value: "never synchronized", color: "blue" },
            synchronized_at: "Never"
          }
        ]
      )
    end
  end
end
