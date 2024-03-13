# frozen_string_literal: true

module Oclc
  module LcCallSlips
    class LcCallSlipJob < LibJob
      attr_reader :report_downloader
    end
  end
end
