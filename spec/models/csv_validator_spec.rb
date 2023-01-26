# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CSVValidator, type: :model do
  describe '#require_headers' do
    it 'does not accept both a CSV string and filename' do
      expect do
        described_class.new(csv_string: '123', csv_filename: '/dev/null').require_headers([])
      end.to raise_error(ArgumentError)
    end

    it 'can validate a CSV string' do
      csv_string = <<~END_CSV
      Column1,Column2
      Dogs,Canis
      Cats,Felis
      END_CSV
      validator = described_class.new(csv_string:)
      expect(validator.require_headers(['Column1', 'Column2'])).to eq(true)
    end

    it 'can validate a file that contains a CSV' do
      validator = described_class.new(csv_filename: Rails.root.join('spec', 'fixtures', 'renew.csv'))
      expect(validator.require_headers(['Barcode', 'Patron Group', 'Expiry Date', 'Primary Identifier'])).to eq(true)
    end

    it 'raises InvalidHeadersError on incorrect columns' do
      csv_string = <<~END_CSV
      WrongColumn1,WrongColumn2
      Dogs,Canis
      Cats,Felis
      END_CSV
      validator = described_class.new(csv_string:)
      expect { validator.require_headers(['Column1', 'Column2']) }.to raise_error(
        CSVValidator::InvalidHeadersError,
        "Missing required headers [\"Column1\", \"Column2\"]\n"\
        'Filename: In-memory string'
      )
    end
  end

  describe '#initialize' do
    it 'requires you to pass either a CSV string or a CSV filename' do
      expect do
        described_class.new
      end.to raise_error(ArgumentError)
    end
  end
end
