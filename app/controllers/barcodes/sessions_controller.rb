# frozen_string_literal: true

class Barcodes::SessionsController < AbsoluteIds::SessionsController
  skip_forgery_protection if: :token_header?

  def self.create_session_job
    Barcodes::CreateSessionJob
  end

  def show
    @session ||= begin
                   AbsoluteId::Session.find_by(user: current_user, id: session_id)
                 end

    if request.format.text?
      render text: @session.to_txt
    else
      respond_to do |format|
        format.json { render json: @session }
        format.yaml { render yaml: @session.to_yaml }
        format.xml { render xml: @session }
      end
    end
  end

  private

  def current_sessions
    @current_sessions ||= begin
                            models = super.select(&:barcode_only?)
                            models.reverse
                          end
  end

  def session_id
    params[:session_id]
  end
end
