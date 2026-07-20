# frozen_string_literal: true
module RecentJobStatuses
  module Views
    class Index < Hanami::View
      expose :statuses do
        RecentJobStatus.all
      end
    end
  end
end
