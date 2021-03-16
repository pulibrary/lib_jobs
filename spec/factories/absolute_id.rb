# frozen_string_literal: true
FactoryBot.define do
  factory :absolute_id do
    value { "32101103191142" }
    check_digit { "2" }
    index { 0 }
    synchronizing { false }
    synchronize_status { AbsoluteId::NEVER_SYNCHRONIZED }
  end
end
