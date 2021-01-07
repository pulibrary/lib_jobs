# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Instance < Object
      def sub_container
        @sub_container ||= SubContainer.new(@repository, @values.sub_container)
      end

      def sub_container=(updated)
        @values[:sub_container] = updated.to_h
      end

      def top_container
        return unless sub_container

        sub_container.top_container
      end
    end
  end
end
