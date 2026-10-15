# frozen_string_literal: true

require_relative '../app'
if Rails.env.local?
  # Lazily load components as they are needed.
  Hanami.prepare
else
  # Proactively load all components; this will fail if we are missing something that
  # any component relies on (e.g. if the database does not yet exist)
  Hanami.boot
end
