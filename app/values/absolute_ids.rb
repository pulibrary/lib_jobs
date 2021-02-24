
module AbsoluteIds
  class InvalidBarcodeError < StandardError; end

  autoload(:BarcodeXmlSerializer, Rails.root.join('app', 'values', 'absolute_ids', 'barcode_xml_serializer'))
  autoload(:Barcode, Rails.root.join('app', 'values', 'absolute_ids', 'barcode'))
end
