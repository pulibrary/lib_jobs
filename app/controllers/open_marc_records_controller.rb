# frozen_string_literal: true
class OpenMarcRecordsController < ApplicationController
  def index
    @data_dumps = OpenMarcRecord.data_dumps.map.with_index.to_h
  end

  def download
    send_file(OpenMarcRecord.file_path(params[:index]))
  end
end
