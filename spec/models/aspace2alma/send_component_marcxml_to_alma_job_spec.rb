# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2alma::SendComponentMarcxmlToAlmaJob do
  def fixture_json(name)
    JSON.parse(file_fixture("aspace2alma/#{name}.json").read)
  end

  subject(:job) { described_class.new }

  let(:frozen_time) { Time.utc(2026, 6, 8, 12, 0, 0) }
  let(:since_in_solr_format) { '2026-06-07T11:59:55Z' }

  let(:flagged_resource) { { 'uri' => '/repositories/5/resources/3950', 'user_defined' => { 'boolean_1' => true } } }
  let(:unflagged_resource) { { 'uri' => '/repositories/5/resources/3207', 'user_defined' => { 'boolean_1' => false } } }
  let(:resolved_ao_json) { fixture_json('resolved_archival_object') }
  let(:client) { instance_double('ArchivesSpace::Client') }

  let(:search_query) do
    { q: %(resource:"/repositories/5/resources/3950" AND system_mtime:[#{since_in_solr_format} TO *]),
      type: ['archival_object'], page: 1, page_size: 250 }
  end
  let(:search_results) { { 'this_page' => 1, 'last_page' => 1, 'results' => [{ 'uri' => '/repositories/5/archival_objects/1074411' }] } }

  around do |example|
    FileUtils.rm_f(described_class::FILENAME)
    example.run
    FileUtils.rm_f(described_class::FILENAME)
  end
  after { Timecop.return }

  before do
    Timecop.freeze(frozen_time)

    allow(Rails.application.config.aspace).to receive(:component_export_flag_field).and_return('boolean_1')

    allow(job).to receive(:aspace_login)
    job.instance_variable_set(:@client, client)
    allow(job).to receive(:sleep)

    allow(job).to receive(:get_all_repo_uris).and_return(['/repositories/5'])
    allow(job).to receive(:get_repo_id_from_uri).with('/repositories/5').and_return('5')

    allow(client).to receive(:get)
      .with('/repositories/5/resources', query: { all_ids: true })
      .and_return(instance_double('ArchivesSpace::Response', parsed: [3207, 3950]))
    allow(job).to receive(:get_resolved_objects_from_ids)
      .with('5', [3207, 3950], 'resources', [])
      .and_return([[flagged_resource, unflagged_resource]])

    allow(client).to receive(:get)
      .with('/repositories/5/search', query: search_query)
      .and_return(instance_double('ArchivesSpace::Response', parsed: search_results))
    allow(job).to receive(:get_resolved_objects_from_ids)
      .with('5', [1_074_411], 'archival_objects', Aspace2alma::ArchivalObjectRecord.resolves)
      .and_return([[resolved_ao_json]])

    allow(Aspace2almaHelper).to receive(:remove_file)
    allow(Aspace2almaHelper).to receive(:rename_file)
    allow(Aspace2almaHelper).to receive(:alma_sftp)
  end

  describe '#run' do
    it 'searches for AOs of flagged resources that were modified since the export last ran' do
      job.run

      expect(client).to have_received(:get).with('/repositories/5/search', query: search_query)
    end

    it 'maps the resolved AOs to marcXML and wraps them in <collection>' do
      job.run

      collection = Nokogiri::XML(File.read(described_class::FILENAME))
      expect(collection.xpath('//marc:record').size).to eq(1)
      expect(collection.at_xpath('//marc:controlfield[@tag="001"]').content).to eq('C0140_c03353')
    end

    context 'when the component records no language but its collection does' do
      let(:flagged_resource) do
        { 'uri' => '/repositories/5/resources/3950', 'user_defined' => { 'boolean_1' => true },
          'lang_materials' => [{ 'language_and_script' => { 'language' => 'spa' } }] }
      end
      let(:resolved_ao_json) do
        fixture_json('resolved_archival_object').merge('lang_materials' => [])
      end

      it "uses the collection's language" do
        job.run

        collection = Nokogiri::XML(File.read(described_class::FILENAME))
        expect(collection.at_xpath('//marc:controlfield[@tag="008"]').content[35..37]).to eq('spa')
      end
    end

    it "renames previous file and sftp's the new one" do
      job.run

      expect(Aspace2almaHelper).to have_received(:remove_file).with('/alma/aspace/marcao_export_old.xml').ordered
      expect(Aspace2almaHelper).to have_received(:rename_file)
        .with('/alma/aspace/marcao_export.xml', '/alma/aspace/marcao_export_old.xml').ordered
      expect(Aspace2almaHelper).to have_received(:alma_sftp).with('marcao_export.xml').ordered
    end

    # catch aos that were edited while an export was running
    it 'tells the next run to look back to the start of the last run' do
      allow(job).to receive(:get_resolved_objects_from_ids)
        .with('5', [1_074_411], 'archival_objects', Aspace2alma::ArchivalObjectRecord.resolves) do
          Timecop.travel(10.minutes)
          [[resolved_ao_json]]
        end

      job.run

      data_set = DataSet.where(category: 'Aspace2Alma_component').order(created_at: :desc).first
      expect(data_set.report_time).to eq(frozen_time)
    end

    it 'logs how many archival object records were exported' do
      allow(Rails.logger).to receive(:info)

      job.run

      expect(Rails.logger).to have_received(:info).with(/exported 1 archival object record\(s\) modified since/)
    end

    it 'records where it started looking' do
      job.run

      expect(DataSet.find_by(category: 'Aspace2Alma_component').data)
        .to eq('exported 1 archival object record(s) modified since 2026-06-07T11:59:55Z')
    end

    context 'when the same job runs again after Alma picked up its file' do
      let(:second_query) do
        { q: %(resource:"/repositories/5/resources/3950" AND system_mtime:[2026-06-08T11:59:55Z TO *]),
          type: ['archival_object'], page: 1, page_size: 250 }
      end

      before do
        allow(client).to receive(:get)
          .with('/repositories/5/search', query: second_query)
          .and_return(instance_double('ArchivesSpace::Response', parsed: search_results))
      end

      it 'searches from the start of its previous run' do
        job.run
        Timecop.freeze(Time.utc(2026, 6, 8, 16, 0, 0))
        job.run

        expect(client).to have_received(:get).with('/repositories/5/search', query: search_query).once
        expect(client).to have_received(:get).with('/repositories/5/search', query: second_query).once
      end
    end

    context 'when the same job runs again before Alma picked up its file' do
      it "searches the previous run's window again" do
        job.run
        Timecop.freeze(frozen_time + 2.hours)
        job.run

        expect(client).to have_received(:get).with('/repositories/5/search', query: search_query).twice
      end
    end

    context "when Alma hasn't picked up the evening run's file yet" do
      let(:since_in_solr_format) { '2026-06-07T03:29:55Z' }

      before do
        DataSet.create!(category: 'Aspace2Alma_component', status: true, report_time: Time.utc(2026, 6, 8, 3, 30, 0),
                        created_at: Time.utc(2026, 6, 8, 3, 40, 0),
                        data: 'exported 2 archival object record(s) modified since 2026-06-07T03:29:55Z')
      end

      it "covers the evening run's changes too" do
        job.run

        expect(client).to have_received(:get).with('/repositories/5/search', query: search_query)
        expect(Aspace2almaHelper).to have_received(:alma_sftp).with('marcao_export.xml')
      end

      context 'and no aos have changed' do
        let(:search_results) { { 'this_page' => 1, 'last_page' => 1, 'results' => [] } }

        it 'leaves the file for Alma' do
          job.run

          expect(Aspace2almaHelper).not_to have_received(:rename_file)
        end
      end

      context 'and the run fails' do
        before { allow(job).to receive(:aspace_login).and_raise(Errno::ECONNREFUSED) }

        it 'leaves the file for Alma' do
          expect { job.run }.to raise_error(Errno::ECONNREFUSED)

          expect(Aspace2almaHelper).not_to have_received(:rename_file)
        end
      end

      context 'and Alma picks it up before the next run' do
        let(:frozen_time) { Time.utc(2026, 6, 8, 16, 0, 0) }
        let(:since_in_solr_format) { '2026-06-08T03:29:55Z' }

        it 'searches from the start of the evening run' do
          job.run

          expect(client).to have_received(:get).with('/repositories/5/search', query: search_query)
        end
      end
    end

    context 'when no aos have changed' do
      let(:search_results) { { 'this_page' => 1, 'last_page' => 1, 'results' => [] } }

      it 'does not send an empty file' do
        job.run

        expect(Aspace2almaHelper).not_to have_received(:alma_sftp)
        expect(File).not_to exist(described_class::FILENAME)
      end

      it "renames the previous file so Alma can't import it a second time" do
        job.run

        expect(Aspace2almaHelper).to have_received(:rename_file)
          .with('/alma/aspace/marcao_export.xml', '/alma/aspace/marcao_export_old.xml')
      end
    end

    context 'when the previous run succeeded' do
      let(:since_in_solr_format) { '2026-06-06T03:29:55Z' }

      before do
        DataSet.create!(category: 'Aspace2Alma_component', status: true, report_time: Time.utc(2026, 6, 6, 3, 30, 0),
                        created_at: Time.utc(2026, 6, 6, 3, 40, 0))
        DataSet.create!(category: 'Aspace2Alma_component', status: false, report_time: Time.utc(2026, 6, 7, 3, 30, 0),
                        created_at: Time.utc(2026, 6, 7, 3, 40, 0))
      end

      it 'searches from the start of the last successful run' do
        job.run

        expect(client).to have_received(:get).with('/repositories/5/search', query: search_query)
      end

      context 'and the given since time is later' do
        subject(:job) { described_class.new(since: Time.utc(2026, 6, 8, 9, 0, 0)) }

        it 'still searches from the start of the last successful run' do
          job.run

          expect(client).to have_received(:get).with('/repositories/5/search', query: search_query)
        end
      end
    end

    context 'when given a since time' do
      subject(:job) { described_class.new(since: Time.utc(2026, 5, 1, 23, 30, 0)) }

      let(:since_in_solr_format) { '2026-05-01T23:30:00Z' }

      before do
        DataSet.create!(category: 'Aspace2Alma_component', status: true, report_time: Time.utc(2026, 6, 8, 9, 0, 0))
      end

      it 'searches from that time instead of the last successful run' do
        job.run

        expect(client).to have_received(:get).with('/repositories/5/search', query: search_query)
      end
    end

    context 'when the resource itself changed since the last run (this includes that the checkbox was checked)' do
      let(:flagged_resource) do
        { 'uri' => '/repositories/5/resources/3950', 'system_mtime' => '2026-06-08T10:00:00Z',
          'user_defined' => { 'boolean_1' => true } }
      end
      let(:search_query) do
        { q: 'resource:"/repositories/5/resources/3950"', type: ['archival_object'], page: 1, page_size: 250 }
      end

      it 'sends all aos' do
        job.run

        expect(client).to have_received(:get).with('/repositories/5/search', query: search_query)
        expect(Aspace2almaHelper).to have_received(:alma_sftp).with('marcao_export.xml')
      end
    end

    context 'when the resource changed before the last run' do
      let(:flagged_resource) do
        { 'uri' => '/repositories/5/resources/3950', 'system_mtime' => '2026-01-15T10:00:00Z',
          'user_defined' => { 'boolean_1' => true } }
      end

      it 'sends only those aos that changed since last time' do
        job.run

        expect(client).to have_received(:get).with('/repositories/5/search', query: search_query)
        expect(job).to have_received(:get_resolved_objects_from_ids)
          .with('5', [1_074_411], 'archival_objects', Aspace2alma::ArchivalObjectRecord.resolves)
        collection = Nokogiri::XML(File.read(described_class::FILENAME))
        expect(collection.xpath('//marc:controlfield[@tag="001"]').map(&:content)).to eq(['C0140_c03353'])
        expect(Aspace2almaHelper).to have_received(:alma_sftp).with('marcao_export.xml')
      end
    end

    context 'when ASpace is unreachable (e.g. during the Saturday maintenance window)' do
      before { allow(job).to receive(:aspace_login).and_raise(Errno::ECONNREFUSED) }

      it 'retries, then gives up without storing a DataSet' do
        expect { job.run }.to raise_error(Errno::ECONNREFUSED)

        expect(job).to have_received(:aspace_login).exactly(described_class::RETRY_ATTEMPTS + 1).times
        expect(Aspace2almaHelper).not_to have_received(:rename_file)
        expect(DataSet.where(category: 'Aspace2Alma_component')).to be_empty
      end
    end

    context 'when an ASpace call times out' do
      before do
        calls = 0
        allow(client).to receive(:get).with('/repositories/5/search', query: search_query) do
          calls += 1
          raise Net::ReadTimeout if calls == 1

          instance_double('ArchivesSpace::Response', parsed: search_results)
        end
      end

      it 'retries and sends the file' do
        job.run

        expect(client).to have_received(:get).with('/repositories/5/search', query: search_query).twice
        expect(job).to have_received(:sleep).with(1).once
        expect(Aspace2almaHelper).to have_received(:alma_sftp).with('marcao_export.xml')
      end
    end

    context 'when an ASpace call keeps timing out' do
      before do
        allow(job).to receive(:get_resolved_objects_from_ids)
          .with('5', [1_074_411], 'archival_objects', Aspace2alma::ArchivalObjectRecord.resolves)
          .and_raise(Net::ReadTimeout)
      end

      it 'fails' do
        expect { job.run }.to raise_error(Net::ReadTimeout)

        expect(Aspace2almaHelper).not_to have_received(:rename_file)
        expect(Aspace2almaHelper).not_to have_received(:alma_sftp)
        expect(DataSet.where(category: 'Aspace2Alma_component')).to be_empty
      end
    end

    context 'when the SFTP upload doesnt succeed' do
      before do
        calls = 0
        allow(Aspace2almaHelper).to receive(:alma_sftp) do
          calls += 1
          raise Net::SSH::Disconnect if calls == 1
        end
      end

      it 'retries the send' do
        job.run

        expect(Aspace2almaHelper).to have_received(:alma_sftp).twice
        expect(DataSet.where(category: 'Aspace2Alma_component').count).to eq(1)
      end
    end

    context 'when something hiccups and the same record gets returned twice' do
      before do
        allow(job).to receive(:get_resolved_objects_from_ids)
          .with('5', [3207, 3950], 'resources', [])
          .and_return([[flagged_resource, unflagged_resource], [flagged_resource]])
        allow(job).to receive(:get_resolved_objects_from_ids)
          .with('5', [1_074_411], 'archival_objects', Aspace2alma::ArchivalObjectRecord.resolves)
          .and_return([[resolved_ao_json], [resolved_ao_json]])
      end

      it 'searches each resource and exports each ao just once' do
        job.run

        expect(client).to have_received(:get).with('/repositories/5/search', query: search_query).once
        collection = Nokogiri::XML(File.read(described_class::FILENAME))
        expect(collection.xpath('//marc:record').size).to eq(1)
      end
    end
  end
end
