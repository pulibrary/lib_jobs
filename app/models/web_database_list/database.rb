# frozen_string_literal: true

require 'csv'

class WebDatabaseList::Database
  attr_reader :id, :name, :description, :alt_names, :url, :friendly_url, :subjects
  def initialize(json)
    parse json
  end

  def to_csv_row
    row = CSV::Row.new([], [])
    self.class.field_names.each do |field|
      row << [field, send(field)]
    end
    row
  end

  def self.field_names
    [:id, :name, :description, :alt_names, :url, :friendly_url, :subjects, :resource_page_url]
  end

  def resource_page_url
    @resource_page_url ||= URI::HTTPS.build(host: 'libguides.princeton.edu', path: "/az/#{name_to_path}").to_s
  end

  private

  def parse(json)
    @id = json['id']
    @name = json['name']
    @description = json['description']
    @alt_names = json['alt_names'] if json['alt_names'].present?
    @url = json['url']
    @friendly_url = json['friendly_url']
    @subjects = if json['subjects'].present?
                  json['subjects'].pluck('name').join(';')
                else
                  ''
                end
  end

  def name_to_path
    first_title = name.split(/\; /).first
    first_title.tr('^a-zA-Z0-9 ', '').downcase.split(' ').join('-')
  end
end
