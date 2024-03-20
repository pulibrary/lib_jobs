# frozen_string_literal: true

RSpec.shared_context 'gobi_isbn' do
  let(:temp_file_one) { Tempfile.new(encoding: 'ascii-8bit') }
  let(:file_name_to_download_one) { 'received_items_published_last_5_years_202403110621.csv' }
  let(:alma_fixture_file_one) { Rails.root.join('spec', 'fixtures', 'gobi', file_name_to_download_one) }
  let(:new_tsv_path) { Rails.root.join('spec', 'fixtures', 'gobi', '2024-03-16-gobi-isbn-updates.tsv') }
  let(:freeze_time) { Time.utc(2024, 3, 16) }

  around do |example|
    temp_file_one.write(File.open(alma_fixture_file_one).read)
    # temp_file_two.write(File.open().read)
    File.delete(new_tsv_path) if File.exist?(new_tsv_path)
    Timecop.freeze(freeze_time) do
      example.run
    end
    File.delete(new_tsv_path) if File.exist?(new_tsv_path)
  end
end
