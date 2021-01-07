
# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class TopContainer < Object
      def barcode
        return unless @values[:barcode]

        @barcode ||= AbsoluteId.find_or_initialize_by(value: @values[:barcode])
      end

      def barcode=(updated)
        @value[:barcode] = updated.value
      end
    end
  end
end
