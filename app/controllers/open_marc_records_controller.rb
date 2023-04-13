# frozen_string_literal: true
class OpenMarcRecordsController < ApplicationController
  def index
    @data_dumps = Dir.children(LibJobs.config[:open_marc_records_location])
  end

  def download
    file = Rails.root.join(LibJobs.config[:open_marc_records_location], "#{params[:file]}.#{params[:format]}")
    raise ActiveRecord::RecordNotFound and return unless File.exists?(file)
    send_file(file)
  end
end
