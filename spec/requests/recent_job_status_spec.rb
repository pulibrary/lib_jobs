# frozen_string_literal: true
require 'rails_helper'
include Dry::Monads[:result]

RSpec.describe '/status', type: :request do
  it 'displays status in a table' do
    RecentJobStatus.register job: :MyNiceJob, status: Success(:great)
    RecentJobStatus.register job: :MyBadJob, status: Failure(:oh_no)

    get '/status'
    parsed = response.parsed_body
    rows = parsed.css('tr')
                 .map { |tr| tr.css('td').map(&:text) }
    expect(rows[0]).to eq(['MyNiceJob', 'success'])
    expect(rows[1]).to eq(['MyBadJob', 'failure'])
  end
end
