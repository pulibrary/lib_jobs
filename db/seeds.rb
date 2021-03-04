# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#

source_client = LibJobs::ArchivesSpace::Client.source
Rails.logger.info("Authenticating...")
source_client.login
Rails.logger.info("Authenticated")

Rails.logger.info("Caching repositories...")
source_client.repositories.each do |repository|
  Rails.logger.info("Cached repository #{repository.uri}...")

  repository.top_containers.each do |top_container|
    Rails.logger.info("Cached container #{top_container.uri}...")
  end

  repository.resources.each do |resources|
    Rails.logger.info("Cached resource #{resource.uri}...")
  end
end

source_client.container_profiles
source_client.locations
