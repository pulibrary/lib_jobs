# frozen_string_literal: true

module Shared
  module Relations
    class NextDateToProcess < Hanami::DB::Relation
      schema :next_date_to_process, infer: true
    end
  end
end
