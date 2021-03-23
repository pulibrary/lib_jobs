# frozen_string_literal: true

<<<<<<< HEAD
class Barcodes::SessionsController < AbsoluteIds::SessionsController
  skip_forgery_protection if: :token_header?

  def self.create_session_job
    Barcodes::CreateSessionJob
=======
class Barcodes::SessionsController < AbsoluteId::SessionsController
  skip_forgery_protection if: :token_header?

  # POST /absolute-ids/sessions
  # POST /absolute-ids/sessions.json
  def create
    authorize!(:create_sessions, AbsoluteId::Session)
    @session = ::AbsoluteIdCreateSessionJob.perform_now(session_attributes: session_params, user_id: current_user.id)

    respond_to do |format|
      format.html do
        redirect_to absolute_ids_path
      end

      format.json do
        head :found, location: absolute_ids_path(format: :json)
      end
    end
  rescue CanCan::AccessDenied
    warning_message = if current_user_params.nil? || current_user.nil?
                        "Denied attempt to create batches of Absolute IDs by the anonymous client #{request.remote_ip}"
                      else
                        "Denied attempt to create batches of Absolute IDs by the user ID #{current_user.id}"
                      end

    Rails.logger.warn(warning_message)

    respond_to do |format|
      format.html do
        redirect_to absolute_ids_path
      end

      format.json { head :forbidden }
    end
  rescue ArgumentError => error
    Rails.logger.warn("Failed to create batches of new Absolute IDs with invalid parameters.")
    Rails.logger.warn(JSON.generate(session_params))
    raise error
  end

  # POST /absolute-ids/sessions/synchronize
  # POST /absolute-ids/sessions/synchronize.json
  def synchronize
    authorize!(:synchronize, AbsoluteId::Session)

    session_id = params[:session_id]
    @session = AbsoluteId::Session.find_by(user: current_user, id: session_id)

    @session.absolute_ids.each do |absolute_id|
      ArchivesSpaceSyncJob.perform_now(user_id: current_user.id, model_id: absolute_id.id)
    end

    respond_to do |format|
      format.json do
        head :found, location: absolute_ids_path(format: :json)
      end
    end
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
>>>>>>> [WIP] Implementing the barcode-only routes
  end

  private

<<<<<<< HEAD
  def current_sessions
    @current_sessions ||= begin
                            models = super.select(&:barcode_only?)
                            models.reverse
                          end
=======
  def session_id
    params[:session_id]
>>>>>>> [WIP] Implementing the barcode-only routes
  end
end
