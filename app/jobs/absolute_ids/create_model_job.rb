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
      location = model_attributes[:location]
      container_profile = model_attributes[:container_profile]
      index = model_attributes[:index]

      persisted = AbsoluteId.where(location: location, container_profile: container_profile)
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
