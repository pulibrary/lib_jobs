# frozen_string_literal: true
require "rails_helper"

RSpec.describe AlmaSftp, type: :model do
  it_behaves_like 'an sftp'
end
