# frozen_string_literal: true
module OpenMarcRecords
  module Views
    class Index < Hanami::View
      include Deps["repos.marc_files"]

      expose :files do
        marc_files.list
      end
    end
  end
end
