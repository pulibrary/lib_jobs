# frozen_string_literal: true

class BarcodesController < AbsoluteIdsController

  # This should be moved to a separate controller
  # GET /barcodes
  # GET /barcodes.json
  def index
    @sessions ||= begin
                    models = AbsoluteId::Session.where(user: current_user)
                    models.reverse
                  end

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @sessions }
    end
  end

  # GET /absolute-ids/:value
  # GET /absolute-ids/:value.json
  # GET /absolute-ids/:value.xml
  def show
    @absolute_id ||= AbsoluteId.find_by(value: value)

    respond_to do |format|
      format.json { render json: @absolute_id }
      format.xml { render xml: @absolute_id }
    end
  end
end
