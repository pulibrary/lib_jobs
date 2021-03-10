# frozen_string_literal: true
# config valid for current version and patch releases of Capistrano

set :application, "lib-jobs"
set :repo_url, "https://github.com/pulibrary/lib_jobs.git"
set :branch, ENV["BRANCH"] || "main"

# Default branch is :main
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/opt/lib-jobs"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

namespace :deploy do
  after :finishing, :aspace_cache do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        #execute :rake, 'lib_jobs:dead_queues', '--trace'
        #execute :rake, 'lib_jobs:absolute_ids:aspace:cache', '--trace'
      end
    end
  end
end

namespace :sidekiq do
  task :quiet do
    on roles(:worker) do
      puts capture("kill -USR1 $(sudo initctl status lib-jobs-workers | grep /running | awk '{print $NF}') || :")
    end
  end
  task :restart do
    on roles(:worker) do
      execute :sudo, :service, "lib-jobs-workers", :restart
    end
  end
end

after "deploy:reverted", "sidekiq:restart"
after "deploy:starting", "sidekiq:quiet"
after "deploy:published", "sidekiq:restart"
