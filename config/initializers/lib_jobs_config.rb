# frozen_string_literal: true
module LibJobs
  def config
    @config ||= environment_yaml.with_indifferent_access
  end

  def all_environment_config
    YAML.safe_load(yaml, aliases: true)
  end

  private

  def environment_yaml
    all_environment_config[Rails.env]
  end

  def yaml
    ERB.new(File.read(Rails.root.join("config", "config.yml"))).result
  end

  module_function :config, :yaml, :environment_yaml, :all_environment_config
end
