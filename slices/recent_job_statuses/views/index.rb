# frozen_string_literal: true
module RecentJobStatuses
  module Views
    class Index < Hanami::View
      Shared::UseAppLayout.new.call(config)

      expose :statuses do
        RecentJobStatus.all
      end
    end
  end
end
