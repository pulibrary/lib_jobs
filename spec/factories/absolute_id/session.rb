# frozen_string_literal: true
FactoryBot.define do
  factory :absolute_id_session, class: "absolute_id/session" do
    user
  end
end
