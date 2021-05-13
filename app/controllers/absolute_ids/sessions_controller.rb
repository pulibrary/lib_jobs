# frozen_string_literal: true

class AbsoluteIds::SessionsController < ApplicationController
  skip_forgery_protection if: :token_header?
  include TokenAuthorizedController

  def self.create_session_job
    AbsoluteIds::CreateSessionJob
  end

  # GET /absolute-ids
  # GET /absolute-ids.json
  def index
    @sessions = current_sessions

    respond_to do |format|
      format.json { render json: @sessions }
      format.html { render :index }
    end
  end

  # POST /absolute-ids/sessions
  # POST /absolute-ids/sessions.json
  def create
    authorize!(:create, AbsoluteId::Session)
    @session = self.class.create_session_job.perform_now(session_attributes: session_params, user_id: current_user.id)

    respond_to do |format|
      format.json do
        head :found, location: absolute_ids_path(format: :json)
      end
    end
  rescue CanCan::AccessDenied
    warning_message = ("Denied attempt to create batches of Absolute IDs by the anonymous client #{request.remote_ip}" if current_user_params.nil? || current_user.nil?)

    Rails.logger.warn(warning_message)

    respond_to do |format|
      format.html do
        redirect_to absolute_ids_path
      end

      format.json { head :forbidden }
    end
  end

  # POST /absolute-ids/sessions/synchronize
  # POST /absolute-ids/sessions/synchronize.json
  def synchronize
    authorize!(:synchronize, AbsoluteId::Session)

    session_id = params[:session_id]
    @session = AbsoluteId::Session.find_by(user: current_user, id: session_id)

    @session.absolute_ids.each do |absolute_id|
      AbsoluteIds::SessionSynchronizeJob.perform_now(user_id: current_user.id, model_id: absolute_id.id)
    end

    respond_to do |format|
      format.json do
        head :found, location: absolute_ids_path(format: :json)
      end
    end
  end

  def show
    @session = current_session
    # I am not certain why this is needed
    return render json: @session if request.headers["Accept"] == 'application/json'

    respond_to do |format|
      format.json { render json: @session } # I am not certain why this is not called
      format.csv { render plain: @session.to_csv, content_type: 'text/csv' }
      format.yaml { render yaml: @session.to_yaml }
      format.xml { render xml: @session }
    end
  end

  private

  def current_session
    @session ||= begin
                   AbsoluteId::Session.find_by(user: current_user, id: session_id)
                 end
  end

  def batches
    @batches ||= begin
                   return [] if @session.nil?

                   @session.batches
                 end
  end

  def absolute_ids
    @absolute_ids ||= begin
                        return [] if @batches.nil?

                        batches.map(&:absolute_ids).flatten
                      end
  end

  def session_id
    params[:session_id]
  end

  def session_params
    params.permit(batches: [
                    :barcode,
                    :batch_size,
                    :source,
                    :valid,
                    absolute_id: [
                      :barcode,
                      :container,
                      container_profile: [
                        :create_time,
                        :id,
                        :lock_version,
                        :system_mtime,
                        :uri,
                        :user_mtime,
                        :name,
                        :prefix
                      ],
                      location: [
                        :create_time,
                        :id,
                        :lock_version,
                        :system_mtime,
                        :uri,
                        :user_mtime,
                        :area,
                        :barcode,
                        :building,
                        :classification,
                        :external_ids,
                        :floor,
                        :functions,
                        :room,
                        :temporary
                      ],
                      repository: [
                        :create_time,
                        :id,
                        :lock_version,
                        :system_mtime,
                        :uri,
                        :user_mtime,
                        :name,
                        :repo_code
                      ],
                      resource: [
                        :create_time,
                        :id,
                        :lock_version,
                        :system_mtime,
                        :uri,
                        :user_mtime,
                        :name,
                        :repo_code
                      ]
                    ]
                  ])

    elements = params.permit!.fetch(:batches, [])
    elements.map(&:to_h).map(&:deep_dup)
  end

  def current_sessions
    @current_sessions ||= begin
                            models = AbsoluteId::Session.where(user: current_user)
                            models.reverse.to_a
                          end
  end
end
