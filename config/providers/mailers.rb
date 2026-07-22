# frozen_string_literal: true

Hanami.app.register_provider(:mailers, namespace: true) do
  prepare do
    require 'hanami/mailer'
  end
  start do
    delivery_method = case Rails.env
                      in 'test'
                        Hanami::Mailer::Delivery::Test.new
                      in 'development' | 'staging'
                        Hanami::Mailer::Delivery::SMTP.new(
                            address: 'localhost',
                            port: 1025
                          )
                      in 'production'
                        Hanami::Mailer::Delivery::SMTP.new(
                            address: 'lib-ponyexpr-prod.princeton.edu',
                            enable_starttls: false
                          )
                      end
    register 'delivery_method', delivery_method
  end
end
