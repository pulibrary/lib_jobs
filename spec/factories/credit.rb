# frozen_string_literal: true
FactoryBot.define do
  factory :credit, class: PeoplesoftBursar::Credit do
    initialize_with { new(patron_id:, amount:, date:) }
    patron_id { "123" }
    amount { 5.50 }
    date { Date.parse('20200630') }
  end
end
