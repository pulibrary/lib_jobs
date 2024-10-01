# frozen_string_literal: true

Rails.application.config.content_security_policy do |policy|
  policy.script_src :self, :https, :unsafe_eval
  policy.object_src :none
  policy.base_uri :none
  policy.frame_ancestors :none
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
