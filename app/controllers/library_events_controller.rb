# frozen_string_literal: true
class LibraryEventsController < ApplicationController
  def index
    generator = WebEvents::EventsFeedGenerator.new
    generator.run
    respond_to do |format|
      format.csv { send_data generator.read_most_recent_report, filename: "library-events.csv" }
    end
  end
end
