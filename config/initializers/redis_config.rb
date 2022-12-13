# frozen_string_literal: true
require "redis"
config_path = Rails.root.join("config", "redis.yml")
env = Rails.env
erb_config = ERB.new(IO.read(config_path)).result
config = YAML.safe_load(erb_config, permitted_classes: [], permitted_symbols: [], aliases: true)[env].with_indifferent_access
Redis.current = Redis.new(config.merge(thread_safe: true))
