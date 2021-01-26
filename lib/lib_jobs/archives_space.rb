# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    autoload(:Object, File.join(File.dirname(__FILE__), 'archives_space', 'object'))
    autoload(:TopContainer, File.join(File.dirname(__FILE__), 'archives_space', 'top_container'))
    autoload(:SubContainer, File.join(File.dirname(__FILE__), 'archives_space', 'sub_container'))
    autoload(:Instance, File.join(File.dirname(__FILE__), 'archives_space', 'instance'))
    autoload(:Resource, File.join(File.dirname(__FILE__), 'archives_space', 'resource'))
    autoload(:Repository, File.join(File.dirname(__FILE__), 'archives_space', 'repository'))
    autoload(:ContainerProfile, File.join(File.dirname(__FILE__), 'archives_space', 'container_profile'))
    autoload(:Location, File.join(File.dirname(__FILE__), 'archives_space', 'location'))
    autoload(:Configuration, File.join(File.dirname(__FILE__), 'archives_space', 'configuration'))
    autoload(:Client, File.join(File.dirname(__FILE__), 'archives_space', 'client'))
  end
end
