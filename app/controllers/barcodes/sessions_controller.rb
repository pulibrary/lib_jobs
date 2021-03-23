# frozen_string_literal: true

class Barcodes::SessionsController < AbsoluteIds::SessionsController
  skip_forgery_protection if: :token_header?

  def self.create_session_job
    Barcodes::CreateSessionJob
  end

  private

  def current_sessions
    @current_sessions ||= begin
                            models = super.select(&:barcode_only?)
                            models.reverse
                          end
  end
end
