# frozen_string_literal: true
module OpenMarcRecords
  module Repos
    # This repository provides access to Marc files on disk
    class MarcFiles
      include Deps['settings']
      include Dry::Monads[:maybe]

      def list
        @list ||= Dir.children(directory_name)
                     .sort_by { |s| s.scan(/\d+/).first.to_i }
      end

      def get_file_path(id)
        if id < list.length
          Some(Hanami.app.root.join(directory_name, list[id]))
        else
          None()
        end
      end

      private

      def directory_name
        settings.open_marc_records_location
      end
    end
  end
end
