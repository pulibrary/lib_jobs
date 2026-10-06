# frozen_string_literal: true
module Aspace2alma
  # MARC rules shared by the collection and component exports
  module MarcRules
    # hosts of VIAF URIs
    VIAF_HOSTS = %w[viaf.org www.viaf.org].freeze
    # sources coded like LC headings
    LC_SOURCES = %w[lcnaf lcsh viaf].freeze

    module_function

    # [subfield code, value] for an identifier, or nil to drop it
    def authority_subfield(identifier, source)
      return if identifier.blank?

      if (viaf_id = viaf_number(identifier, source))
        ['1', "http://viaf.org/viaf/#{viaf_id}"]
      elsif web_uri?(identifier) && !identifier.match?(/viaf/i) && source != 'viaf'
        ['0', identifier.strip]
      end
    end

    # LC-coded source?
    def lc_source?(source)
      LC_SOURCES.include?(source)
    end

    # http or https URI?
    def web_uri?(identifier)
      uri = URI.parse(identifier.strip)
      %w[http https].include?(uri.scheme) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end

    # VIAF number from an identifier
    def viaf_number(identifier, source)
      bare_number = identifier.strip[/\A\(?viaf\)?[\s:]*(\d+)\z/i, 1]
      bare_number ||= identifier.strip[/\A\d+\z/] if source == 'viaf'
      return bare_number if bare_number

      uri = URI.parse(identifier.strip)
      return unless VIAF_HOSTS.include?(uri.host&.downcase)

      uri.path[%r{\A(?:/[a-z]{2})?/viaf/(\d+)/?\z}, 1]
    rescue URI::InvalidURIError
      nil
    end
  end
end
