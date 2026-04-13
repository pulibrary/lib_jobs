# frozen_string_literal: true
# `Traverse.new.call` runs the provided block on the array.
# As long as the block returns Success, it behaves
# like Array#map, returning every value wrapped in
# Success(Array).
# As soon as it hits Failure, it will return the
# Failure and stop processing the array.
class Traverse
  include Dry::Monads[:result]
  def call(array)
    array.reduce(Success([])) do |accumulator, el|
      result = yield(el)
      case result
      when Success
        accumulator.fmap { |accumulated| accumulated.push(result.value!) }
      else
        break result
      end
    end
  end
end
