# frozen_string_literal: true
class LibraryDatabasesController < ApplicationController
  def index
    feed = WebDatabaseList::DatabasesFeed.new
    feed.run
    respond_to do |format|
      format.csv { send_data feed.read_most_recent_report, filename: "library-databases.csv" }
    end
  end
end
