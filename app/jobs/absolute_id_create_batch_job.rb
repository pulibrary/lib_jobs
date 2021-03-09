class AbsoluteIdCreateBatchJob < ApplicationJob
  def perform(properties:, user_id:)
    @user_id = user_id
    create_batch(properties)
  end

  private

  def create_batch(batch_properties)
    batch_size = batch_properties[:batch_size]
    params_valid = batch_properties[:valid]
    raise ArgumentError unless params_valid

    # Use the same set of params for each AbID
    absolute_id_params = batch_properties[:absolute_id]

    children = batch_size.times.map do |child_index|
      properties = absolute_id_params.deep_dup
      properties[:index] = child_index
      model_id = AbsoluteIdCreateJob.perform_now(properties: properties, user_id: @user_id)
      AbsoluteId.find(model_id)
    end

    if !children.empty?
      batch = AbsoluteId::Batch.create(absolute_ids: children, user: current_user)
      batch.save!
      Rails.logger.info("Batch created: #{batch.id}")
      batch.id
    end
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
