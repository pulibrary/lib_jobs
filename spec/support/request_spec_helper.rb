# frozen_string_literal: true

module RequestSpecHelper
  include Warden::Test::Helpers

  def self.included(base)
    base.before { Warden.test_mode! }
    base.after { Warden.test_reset! }
  end

  def login_as(user, scope: :user)
    user.reload
    super(user, scope: scope, run_callbacks: false)
  end

  def logout(user = :user)
    super(user)
  end
end
