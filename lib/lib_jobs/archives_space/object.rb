# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Object
      def self.model_class
        raise(NotImplementedError, "#{self} is an abstract class, and does not have a corresponding ActiveRecord model.")
      end

      def self.model_class_exists?
        false
      end

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
                          return nil if create_time.nil?

                          segments = create_time.split('T')
                          segments.first
                        end
      end

      # This is what gets serialized into the model
      # This should match what is in self.class.model_class#properties
      def attributes
        {
          create_time: create_time,
          id: id,
          lock_version: lock_version,
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
        return false unless id == other.id

        attributes == other.attributes
      end

      def cache
        self.class.model_class.cache(self)
      end

      def to_model
        self.class.model_class.build_from_resource(self)
      end

      def find_model
        self.class.model_class.find_by(uri: uri)
      end

      def find_or_create_model
        find_model || begin
                        to_model.save
                        to_model
                      end
      end

      private

      # Can this be removed?
      def generate_uri
        @values.uri
      end
    end
  end
end
