# frozen_string_literal: true
class AbsoluteIdCreateMarcSourceRecordJob < AbsoluteIdCreateRecordJob
  def perform(properties:, user_id:)
    @user_id = user_id
    @index = properties[:index]

    create_absolute_id(properties, @index)
  end

  private

  def create_absolute_id(properties, index)
    build_attributes = properties.deep_dup

    location = build_attributes[:location]
    container_profile = build_attributes[:container_profile]

    persisted = AbsoluteId.where(location: location, container_profile: container_profile)
    if !persisted.empty?
      # This should not need to be case into an Integer, but this is in place for a PostgreSQL error
      index = persisted.last.index.to_i + 1
    elsif index.zero?
      index = 1
    end

    # This should not need to be case into an Integer, but this is in place for a PostgreSQL error
    build_attributes[:index] = index.to_s

    # Build and persist the AbId
    generated = AbsoluteId.generate(**build_attributes)
    generated.save!
    generated.id
  end

  def current_user
    @current_user ||= User.find_by(id: @user_id)
  end

  def current_client
    @current_client ||= begin
                          source_client = LibJobs::ArchivesSpace::Client.source
                          source_client.login
                          source_client
                        end
  end
end
