# frozen_string_literal: true

module Gobi
  class IsbnReportJob < LibJob
    def initialize
      super(category: 'Gobi:IsbnReports')
    end

    def handle(data_set:)
      data_set
    end
  end
end
