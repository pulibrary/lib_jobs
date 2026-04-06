# frozen_string_literal: true
class RecentJobStatusController < ApplicationController
  def index
    @statuses = RecentJobStatus.all
  end
end
