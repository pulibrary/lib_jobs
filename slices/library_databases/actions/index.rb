# frozen_string_literal: true
module LibraryDatabases
  module Actions
    class Index < LibJobsHanami::Action
      def handle(_request, response)
        feed = WebDatabaseList::DatabasesFeed.new
        feed.run
        response.format = :csv
        response.body = feed.read_most_recent_report
      end
    end
  end
end
