# frozen_string_literal: true
module LibraryEvents
  module Actions
    class Index < LibJobsHanami::Action
      def handle(_request, response)
        generator = WebEvents::EventsFeedGenerator.new
        generator.run

        response.format = :csv
        response.body = generator.read_most_recent_report
      end
    end
  end
end
