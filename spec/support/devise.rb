# frozen_string_literal: true
require_relative "request_spec_helper"

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include RequestSpecHelper, type: :request
  config.include RequestSpecHelper, type: :system
end
