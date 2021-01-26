# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

AbsoluteId::Location.create_configured

rounds = 13 - AbsoluteId.all.length
client = LibJobs::ArchivesSpace::Client.default
rounds.times.each do
  locations = AbsoluteId::Location.all
  index = rand(0..locations.length - 1)
  random_location = locations[index]

  repository_index = rand(1..rounds)
  repository_uri = "#{client.base_uri}repositories/#{repository_index}"
  resource_index = rand(1..rounds)
  resource_uri = "#{repository_uri}/resources/#{resource_index}"

  built = AbsoluteId.generate(location: random_location.value, repository_uri: repository_uri, resource_uri: resource_uri)
end
