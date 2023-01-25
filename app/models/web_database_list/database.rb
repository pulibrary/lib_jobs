# frozen_string_literal: true

class WebDatabaseList::Database
  attr_reader :id, :name, :description, :alt_names, :url, :friendly_url, :subjects
  def initialize(json)
    parse json
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
