# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Shared::Traverse do
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
  it 'can create an array of arrays' do
    my_array = [1, 2, 3]
    result = described_class.new.call(my_array) { Success(['hello', 'from', it]) }
    expect(result).to eq(Success([
                                   ['hello', 'from', 1],
                                   ['hello', 'from', 2],
                                   ['hello', 'from', 3]
                                 ]))
  end
  it 'can create an array of hashes' do
    my_array = [1, 2, 3]
    result = described_class.new.call(my_array) { Success({ my_favorite: it }) }
    expect(result).to eq(Success([
                                   { my_favorite: 1 },
                                   { my_favorite: 2 },
                                   { my_favorite: 3 }
                                 ]))
  end
end
