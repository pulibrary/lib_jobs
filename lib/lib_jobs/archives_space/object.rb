# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Object
      def self.parse_id(attributes)
        uri = attributes[:uri]
        segments = uri.split("/")
        segments.last
      end

      attr_reader :id,
                  :create_time,
                  :lock_version,
                  :system_mtime,
                  :user_mtime,
                  :uri

      def initialize(attributes)
        normalized = attributes.deep_symbolize_keys
        @values = OpenStruct.new(normalized)

        @client = @values.client
        @create_time = @values.create_time
        @system_mtime = @values.system_mtime
        @user_mtime = @values.user_mtime
        @lock_version = @values.lock_version

        @id = @values.id || self.class.parse_id(attributes)
        @uri = generate_uri
      end

      def start_date
        @start_date ||= begin
                          segments = create_time.split('T')
                          segments.first
                        end
      end

      def attributes
        {
          create_time: create_time,
          id: id,
          system_mtime: system_mtime,
          uri: uri,
          user_mtime: user_mtime
        }
      end

      def to_h
        attributes
      end

      def as_json(**_options)
        attributes
      end

      def client
        @client ||= begin
                      source_client = LibJobs::ArchivesSpace::Client.source
                      @base_uri = source_client.config.base_uri
                      source_client.login
                      source_client
                    end
      end

      def base_uri
        @base_uri ||= if @client.nil?
                        LibJobs::ArchivesSpace::Configuration.source.base_uri
                      else
                        client.config.base_uri
                      end
      end

      def eql?(other)
        return false unless id === other.id

        attributes === other.attributes
      end

      private

      def generate_uri
        URI.join(base_uri, @values.uri)
      end
    end
  end
end
