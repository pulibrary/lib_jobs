# frozen_string_literal: true

class AbsoluteIdsController < ApplicationController
  # GET /absolute-ids
  # GET /absolute-ids.json
  def index
    @absolute_ids ||= model.all

    respond_to do |format|
      format.html { render html: @absolute_ids }
      format.json { render json: @absolute_ids }
    end
  end

  # GET /absolute-ids/:id
  # GET /absolute-ids/:id.json
  def show
    @absolute_id ||= model.find(value)

    respond_to do |format|
      format.html { render html: @absolute_id }
      format.json { render json: @absolute_id }
    end
  end

  # POST /absolute-ids
  # POST /absolute-ids.json
  def create
    @absolute_id = model.build

    if @absolute_id.save
      redirect_to @absolute_id
    else
      redirect_to :index
    end
  end

  private

  def model
    AbsoluteId
  end

  def value
    params[:value]
  end
end
