# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Traverse do
  include Dry::Monads[:result]
  it 'returns an array wrapped in Success if everything is Success' do
    my_array = [1, 2, 3]
    processed = []
    result = described_class.new.call(my_array) do
      processed << it
      Success(it)
    end

    expect(result).to eq(Success([1, 2, 3]))
    expect(processed).to eq([1, 2, 3])
  end
  it 'stops processing if there is a Failure' do
    my_array = [1, 2, 3]
    processed = []
    result = described_class.new.call(my_array) do
      processed << it
      if it <= 1
        Success(it)
      else
        Failure('Found a value higher than 1!')
      end
    end

    expect(result).to eq(Failure('Found a value higher than 1!'))
    expect(processed).to eq([1, 2])
  end
end
