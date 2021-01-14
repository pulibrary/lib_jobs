# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

AbsoluteId::Location.create_configured

rounds = 13 - AbsoluteId.all.length
rounds.times.each do
  locations = AbsoluteId::Location.all
  index = rand(0..locations.length - 1)
  random_location = locations[index]

  AbsoluteId.generate(location: random_location)
end
