# frozen_string_literal: true
class DataSetsController < ApplicationController
  before_action :set_data_set, only: [:show, :edit, :update, :destroy]
  before_action :redirect_clear_filters, only: [:index]

  # GET /data_sets
  # GET /data_sets.json
  def index
    @data_sets = DataSetList.new(filter_data_sets)
  end

  # GET /data_sets/1
  # GET /data_sets/1.json
  def show; end

  # GET /data_sets/new
  def new
    @data_set = DataSet.new
  end

  # GET /data_sets/1/edit
  def edit; end

  # POST /data_sets
  # POST /data_sets.json
  def create
    @data_set = DataSet.new(data_set_params)

    respond_to do |format|
      if @data_set.save
        format.html { redirect_to @data_set, notice: 'Data set was successfully created.' }
        format.json { render :show, status: :created, location: @data_set }
      else
        format.html { render :new }
        format.json { render json: @data_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /data_sets/1
  # PATCH/PUT /data_sets/1.json
  def update
    respond_to do |format|
      if @data_set.update(data_set_params)
        format.html { redirect_to @data_set, notice: 'Data set was successfully updated.' }
        format.json { render :show, status: :ok, location: @data_set }
      else
        format.html { render :edit }
        format.json { render json: @data_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /data_sets/1
  # DELETE /data_sets/1.json
  def destroy
    @data_set.destroy
    respond_to do |format|
      format.html { redirect_to data_sets_url, notice: 'Data set was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

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
    @data_set = DataSet.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def data_set_params
    params.fetch(:data_set, {})
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
