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
end
