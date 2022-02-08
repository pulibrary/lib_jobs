# frozen_string_literal: true
class RenewController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    xml_data = request.body.read
    Rails.logger.warn("Got a Renew request\n#{xml_data}\n")
    renew_item = NCIPRenew::RenewItem.new(Nokogiri::XML(xml_data))
    respond_to do |format|
      format.xml { send_data renew_item.response }
    end
  end
end
