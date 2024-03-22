# frozen_string_literal: true
require "rails_helper"

RSpec.describe AlmaSftp, type: :model do
  include_context 'sftp'
  it_behaves_like 'an sftp'
end
