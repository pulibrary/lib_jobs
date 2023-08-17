# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for creating a new
  # 852 MARC field (location), using data from
  # an existing 852 field
  class MarcLocationFieldFactory
    def initialize(original_field)
      @original_field = original_field
    end

    def generate
      new_field = MARC::DataField.new('852', @original_field.indicator1, @original_field.indicator2)
      location = "#{@original_field['b']}$#{@original_field['c']}"
      call_num = call_num_from852
      holding_id = @original_field['8']
      new_field.append(MARC::Subfield.new('0', holding_id))
      new_field.append(MARC::Subfield.new('b', location))
      new_field.append(MARC::Subfield.new('h', call_num))
      @original_field.subfields.each do |subfield|
        next if %w[b c h i 8].include?(subfield.code)
        new_field.append(MARC::Subfield.new(subfield.code, subfield.value))
      end
      new_field
    end

    private

    def call_num_from852
      call_num = @original_field['h'].to_s
      call_num = call_num.dup
      call_num << " #{@original_field['i']}" if @original_field['i']
      call_num.strip
    end
  end
end
