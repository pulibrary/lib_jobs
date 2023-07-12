# frozen_string_literal: true
module AlmaSubmitCollection
  class AlmaSubmitCollectionJob < LibJob
    def handle(data_set:)
      data_set.data = "20 records processed."
      data_set
    end
  end
end
