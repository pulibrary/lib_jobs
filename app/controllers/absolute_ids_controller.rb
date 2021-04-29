# frozen_string_literal: true

class AbsoluteIdsController < ApplicationController
  helper_method :index_status, :table_columns
  skip_forgery_protection if: :token_header?
  include TokenAuthorizedController

  def table_columns
    [
      { name: 'label', display_name: 'Identifier', align: 'left', sortable: true },
      { name: 'barcode', display_name: 'Barcode', align: 'left', sortable: true, ascending: 'undefined' },
      { name: 'location', display_name: 'Location', align: 'left', sortable: false },
      { name: 'container_profile', display_name: 'Container Profile', align: 'left', sortable: false },
      { name: 'repository', display_name: 'Repository', align: 'left', sortable: false },
      { name: 'resource', display_name: 'ASpace Resource', align: 'left', sortable: false },
      { name: 'container', display_name: 'ASpace Container', align: 'left', sortable: false },
      { name: 'user', display_name: 'User', align: 'left', sortable: false },
      { name: 'status', display_name: 'Synchronization', align: 'left', sortable: false, datatype: 'constant' }
    ]
  end

  # GET /absolute-ids/:value
  # GET /absolute-ids/:value.json
  # GET /absolute-ids/:value.xml
  def show
    @absolute_id ||= AbsoluteId.find_by(value: value_param)

    respond_to do |format|
      format.json { render json: @absolute_id }
      format.xml { render xml: @absolute_id }
    end
  end

  private

  def value_param
    params[:value]
  end
end
