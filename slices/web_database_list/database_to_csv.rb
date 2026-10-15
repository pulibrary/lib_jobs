# frozen_string_literal: true

require 'csv'

module WebDatabaseList
  # This class is responsible for taking JSON about a database and converting it to a CSV::Row
  class DatabaseToCSV
    def call(json)
      CSV::Row.new(field_names, [
                     json['id'],
                     json['name'],
                     json['description'],
                     json['alt_names'].presence,
                     json['url'],
                     json['friendly_url'],
                     json['subjects'].present? ? json['subjects'].pluck('name').join(';') : ''
                   ])
    end

    def field_names = %i[id name description alt_names url friendly_url subjects]
  end
end
