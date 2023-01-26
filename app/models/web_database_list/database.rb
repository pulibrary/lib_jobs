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
      row << [field, instance_variable_get("@#{field}")]
    end
    row
  end

  def self.field_names
    [:id, :name, :description, :alt_names, :url, :friendly_url, :subjects]
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
                  json['subjects'].map { |subject| subject['name'] }.join(';')
                else
                  ''
                end
  end
end
