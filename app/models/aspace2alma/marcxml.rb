# frozen_string_literal: true
module Aspace2alma
  # MARCXML collection wrapper
  module Marcxml
    # opening collection tag
    # rubocop:disable Layout/LineLength
    COLLECTION_START = '<collection xmlns="http://www.loc.gov/MARC21/slim" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">'
    # rubocop:enable Layout/LineLength
    # closing collection tag
    COLLECTION_END = '</collection>'
  end
end
