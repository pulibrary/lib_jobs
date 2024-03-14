# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MarcCollectionDocumentCallbacks do
  let(:io) { StringIO.new }
  let(:document_callbacks) { described_class.new(io) }
  describe '#start_element' do
    it 'writes the opening tag with attributes' do
      document_callbacks.start_element('datafield', [
                                         ['tag', '245'],
                                         ['ind1', '0'],
                                         ['ind2', '0']
                                       ])
      expect(io.string).to eq('<datafield tag="245" ind1="0" ind2="0">')
    end
    it "writes the namespace if the <collection> doesn't already have it" do
      document_callbacks.start_element('collection', [])
      expect(io.string).to eq('<collection xmlns="http://www.loc.gov/MARC21/slim">')
    end
    it "just writes the opening tag if no attributes supplied" do
      document_callbacks.start_element('record', [])
      expect(io.string).to eq('<record>')
    end
  end

  describe '#characters' do
    it "escapes special XML characters" do
      # Nokogiri's SAX parser gives unfrozen strings to this callback, so we use the +
      # in this test to make sure the string we pass is similarly unfrozen
      document_callbacks.characters(+'Vols. for 1972-<1982> called also vyp. 1-<8/2>.')
      expect(io.string).to eq('Vols. for 1972-&lt;1982&gt; called also vyp. 1-&lt;8/2&gt;.')
    end
  end
end
