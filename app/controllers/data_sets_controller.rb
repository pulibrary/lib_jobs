# frozen_string_literal: true
class DataSetsController < ApplicationController
  before_action :set_data_set, only: [:show]
  before_action :redirect_clear_filters, only: [:index]

  # GET /data_sets
  # GET /data_sets.json
  def index
    @data_sets = DataSetList.new(filter_data_sets)
  end

  # GET /data_sets/1
  # GET /data_sets/1.json
  def show; end

  def latest
    authorize! :get_latest, DataSet
    file_name = latest_params[:category].underscore
    category = file_name.camelize
    data_set = DataSet.where(category:, status: true).sort_by(&:report_time).last

    raise ActionController::RoutingError, 'Not Found' if data_set.blank?

    respond_with_data(data_set:, file_name:)
  rescue CanCan::AccessDenied
    respond_with_error
  end

  private

  def respond_with_data(data_set:, file_name:)
    data_reply = if data_set.data.present?
                   data_set.data
                 else
                   file = File.new(data_set.data_file)
                   file.read
                 end

    respond_to do |format|
      format.text { send_data data_reply, file_name: "#{file_name}.txt" }
      format.csv { send_data data_reply, file_name: "#{file_name}.csv" }
      format.json { send_data data_reply, file_name: "#{file_name}.json" }
    end
  end

  def respond_with_error
    warning_message = if current_user_params.nil?
                        "Denied attempt to get Latest Dataset by the anonymous client #{request.remote_ip}. #{params}"
                      else
                        "Denied attempt to get Latest Dataset by the user ID #{current_user_id}. #{params}"
                      end

    Rails.logger.warn(warning_message)

    respond_to do |format|
      format.text { head :forbidden }
      format.csv { head :forbidden }
      format.json { head :forbidden }
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_data_set
    @data_set = DataSet.find(params.expect(:id))
  end

  def index_params
    params.permit(:category, :report_date, :report_time, :commit)
  end

  def latest_params
    params.permit(:category)
  end

  def filter_data_sets
    category = index_params[:category]

    data_sets = DataSet.all
    data_sets = data_sets.where(category:) if category.present?
    data_sets = DataSet.filter_by_date(report_date: index_params[:report_date], query_context: data_sets)
    data_sets = DataSet.filter_by_time(report_time: index_params[:report_time], query_context: data_sets)
    # Put most recent reports first on list
    data_sets.order(report_time: :desc)
  end

  def redirect_clear_filters
    redirect_to root_path if index_params[:commit] == "Clear Filters"
  end
end
