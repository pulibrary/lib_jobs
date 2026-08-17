# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebEvents::Operations::CreateCSV do
  before do
    stub_request(:get, "https://libcal.princeton.edu/ical_subscribe.php?cid=12260&k=79a5e62a54")
      .to_return(status: 200, headers: {},
                 body: File.new(Rails.root.join('spec', 'fixtures', 'files', 'libcal_events.ics')))
  end

  describe('CSV file generation') do
    let(:file_path) { Pathname.new(Rails.root.join('tmp', "events.csv")) }
    let(:first_row) do
      [
        'LibCal-12260-9613672',
        '30 Minutes Towards Better Bibliographies and Footnotes! (online)',
        'This 30-minute workshop will focus on Zotero, but will also briefly '\
        'introduce you to other similar tools, including Mendeley and Endnote. '\
        'We will cover setting up an account, importing citations from library '\
        'databases and web pages, and deploying the references into a Word '\
        'document. Here is the Zoom link: https://princeton.zoom.us/j/2312568598'\
        "\n\nPlease watch this six-minute video before the workshop: "\
        "https://vimeo.com/369873151\n\n",
        '', '2023-04-07 16:00:00 UTC', '2023-04-07 16:30:00 UTC',
        'https://libcal.princeton.edu/event/9613672',
        "Bibliographies\tManaging References\tWorkshops"
      ]
    end

    around do |example|
      File.delete(file_path) if File.exist?(file_path)
      example.run
      File.delete(file_path) if File.exist?(file_path)
    end

    it 'creates a CSV file' do
      described_class.new.call(filename: file_path)
      expect(File.exist?(file_path)).to be true
    end

    it 'the CSV file has a header row and one row for each event' do
      described_class.new.call(filename: file_path)
      expect(CSV.read(file_path).length).to eq(7)
    end

    it 'the first row of data is correct' do
      described_class.new.call(filename: file_path)
      expect(CSV.read(file_path).second).to eq(first_row)
    end
  end
  it 'returns the filename wrapped in success' do
    expect(described_class.new.call(filename: 'tmp/my-nice-file.csv')).to eq(
      Success('tmp/my-nice-file.csv')
    )
  end
end
