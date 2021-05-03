# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteId::Session, type: :model do
  subject(:session) do
    described_class.new(
      batches: [absolute_id_batch]
    )
  end

  let(:user) { create(:user) }
  let(:absolute_id1) { create(:absolute_id, value: '32101103191142', check_digit: '2', index: 0) }
  let(:absolute_id2) { create(:absolute_id, value: '32101103191159', check_digit: '9', index: 1) }
  let(:absolute_id_batch) { create(:absolute_id_batch, absolute_ids: [absolute_id1, absolute_id2], user: user) }
  let(:absolute_id_session) { create(:absolute_id_session, batches: [absolute_id_batch], user: user) }

  let(:level) { 'series' }
  let(:ref_id) { '836QX399J' }
  let(:title) { 'Archival Object Title' }
  let(:create_time) { '2021-01-23T18:03:11Z' }
  let(:system_mtime) { '2021-01-23T18:03:11Z' }
  let(:user_mtime) { '2021-01-23T18:03:11Z' }
  let(:repository_id) { '1' }
  let(:uri) { "http://localhost:8089/repositories/#{repository_id}/archival_objects/1" }
  let(:id) { '1' }
  let(:lock_version) { 1 }
  let(:json_resource) do
    {
      create_time: create_time,
      id: id,
      lock_version: lock_version,
      system_mtime: system_mtime,
      uri: uri,
      user_mtime: user_mtime,
      level: level,
      ref_id: ref_id,
      title: title
    }
  end

  describe '#synchronized?' do
    it 'indicates whether or not all of the AbIDs have been synchronized with ArchivesSpace' do
      expect(session.synchronized?).to be false
    end

    context 'when the AbIDs are synchronized' do
      let(:absolute_id1) { create(:absolute_id, value: '32101103191142', check_digit: '2', index: 0, synchronized_at: DateTime.current) }
      let(:absolute_id2) { create(:absolute_id, value: '32101103191159', check_digit: '9', index: 1, synchronized_at: DateTime.current) }

      it 'indicates whether or not all of the AbIDs have been synchronized with ArchivesSpace' do
        expect(session.synchronized?).to be true
      end
    end
  end

  describe '#synchronizing?' do
    it 'indicates whether or not all of the AbIDs are currently synchronizing with ArchivesSpace' do
      expect(session.synchronizing?).to be false
    end

    context 'when the AbIDs are synchronizing' do
      let(:absolute_id1) { create(:absolute_id, value: '32101103191142', check_digit: '2', index: 0, synchronizing: true) }
      let(:absolute_id2) { create(:absolute_id, value: '32101103191159', check_digit: '9', index: 1, synchronizing: true) }

      it 'indicates whether or not all of the AbIDs have been synchronized with ArchivesSpace' do
        expect(session.synchronizing?).to be true
      end
    end
  end
end
