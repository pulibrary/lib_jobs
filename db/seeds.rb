# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

rounds = 13 - AbsoluteId.all.length
client = LibJobs::ArchivesSpace::Client.default
rounds.times.each do
  location_index = rand(1..rounds)
  location_uri = "#{client.base_uri}locations/#{location_index}"
  location_building = "Test Location #{location_index}"
  location = {
    id: location_index,
    building: location_building,
    uri: location_uri
  }

  repository_index = rand(1..rounds)
  repository_uri = "#{client.base_uri}repositories/#{repository_index}"
  repository_name = "Test Repository #{repository_index}"
  repository = {
    id: repository_index,
    name: repository_name,
    uri: repository_uri
  }

  resource_index = rand(1..rounds)
  resource_uri = "#{repository_uri}/resources/#{resource_index}"
  resource_title = "Test Resource #{resource_index}"
  resource_level = "item"
  resource_ead_location = "116451DKA"
  resource = {
    id: resource_index,
    title: resource_title,
    level: resource_level,
    ead_location: resource_ead_location,
    uri: resource_uri
  }

  container_index = rand(1..rounds)
  container_uri = "#{repository_uri}/top_containers/#{container_index}"
  container_indicator = "73516PYH"
  container_type = "box"
  container = {
    id: container_index,
    indicator: container_indicator,
    type: container_type,
    uri: container_uri
  }

  container_profile_index = rand(1..rounds)
  container_profile_uri = "#{repository_uri}/containers/#{container_index}"
  container_profile_name = if container_profile_index % 2 == 0
                             "mss"
                           else
                             "mudd"
                           end
  container_profile = {
    id: container_profile_index,
    name: container_profile_name,
    uri: container_profile_uri
  }

  built = AbsoluteId.generate(
    location: location,
    container_profile: container_profile,

    repository: repository,
    resource: resource,
    container: container
  )
end
