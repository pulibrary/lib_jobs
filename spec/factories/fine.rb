# frozen_string_literal: true
FactoryBot.define do
  factory :fine, class: PeoplesoftBursar::Fine do
    initialize_with { new(patron_id: patron_id, amount: amount, date: date, fine_id: fine_id, fine_type: fine_type) }
    patron_id { "123" }
    amount { 5.50 }
    date { Date.parse('20200630') }
    fine_id { "123" }
    fine_type { "Library Fines" }
  end
end
