# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for creating a new
  # associated holding field (583, 866, 867, or 868),
  # using data from an existing associated holding field
  class MarcAssociatedHoldingFieldFactory
    def initialize(original_field)
      @original_field = original_field
    end

    def generate
      new_field = MARC::DataField.new(@original_field.tag,
                                      @original_field.indicator1,
                                      @original_field.indicator2)
      @original_field.subfields.each do |subfield|
        new_code = subfield.code
        new_code = '0' if new_code == '8'
        new_field.append(MARC::Subfield.new(new_code, subfield.value))
      end
    end
  end
end
