# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2almaHelper do
  describe '.rotate_file' do
    before do
      allow(described_class).to receive(:remove_file)
      allow(described_class).to receive(:rename_file)
    end

    it 'removes the previous _old file, then renames the current file to _old' do
      described_class.rotate_file('MARC_out.xml')

      expect(described_class).to have_received(:remove_file).with('/alma/aspace/MARC_out_old.xml').ordered
      expect(described_class).to have_received(:rename_file)
        .with('/alma/aspace/MARC_out.xml', '/alma/aspace/MARC_out_old.xml').ordered
    end

    it 'renames marcao_export.xml to marcao_export_old.xml' do
      described_class.rotate_file('marcao_export.xml')

      expect(described_class).to have_received(:rename_file)
        .with('/alma/aspace/marcao_export.xml', '/alma/aspace/marcao_export_old.xml')
    end
  end
end
