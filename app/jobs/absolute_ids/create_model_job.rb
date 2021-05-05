# frozen_string_literal: true
module AbsoluteIds
  class CreateModelJob < BaseJob
    def self.aspace_source_job
      CreateModelFromAspaceJob
    end

    def self.marc_source_job
      CreateModelFromMarcJob
    end

    def self.polymorphic_perform(method, **args)
      properties = args[:properties]
      source = properties.delete(:source)
      args[:properties] = properties

      method_name = "perform_#{method}".to_sym

      case source
      when 'aspace'
        aspace_source_job.send(method_name, **args)
      when 'marc'
        marc_source_job.send(method_name, **args)
      else
        raise(NotImplementedError, "Unsupported or nil source provided for #{self}: #{source}")
      end
    end

    def self.polymorphic_perform_now(**args)
      polymorphic_perform(:now, **args)
    end

    def self.polymorphic_perform_later(**args)
      polymorphic_perform(:later, **args)
    end

    private

    def build_model_index(**model_attributes)
      pool_key = nil
      prefix = nil
      begin
        location = LibJobs::ArchivesSpace::Location.new(JSON.parse(model_attributes[:location], symbolize_names: true))
        pool_key = location.pool_key
        container_profile = JSON.parse(model_attributes[:container_profile], symbolize_names: true)
        prefix = container_profile[:prefix] || "unknown"
      rescue JSON::ParserError
        pool_key = "global"
        prefix = "other"
      end
      index = model_attributes[:index]

      persisted = AbsoluteId.where(pool_identifier: "#{pool_key}-#{prefix}").order(index: :desc)
      persisted_with_index = persisted.where.not(index: nil)
      if !persisted_with_index.empty?
        persisted_with_index.last.index.to_i + 1
      elsif index.zero?
        1
      end
    end

    # Build and persist the AbId
    def create_absolute_id(**model_attributes)
      generated = AbsoluteId.generate(**model_attributes)
      generated.save!
      generated.id
    end
  end
end
