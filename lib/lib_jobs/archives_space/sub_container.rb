# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class SubContainer < Object
      def top_container
        @top_container_object ||= begin
                                    binding.pry
                                    top_container_values = @values[:top_container]
                                    return unless top_container_values

                                    top_container_id = top_container_values[:ref]
                                    return unless top_container_id

                                    @repository.find_top_container(id: top_container_id)
                                  end
      end

      def top_container=(updated)
        @top_container_object = updated
        @values[:top_container] = { ref: @top_container_object.id }
      end
    end
  end
end
