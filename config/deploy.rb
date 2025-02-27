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
#
#   # You can/ should apply this command to a subset of hosts
# cap --hosts=lib-jobs-staging2.lib.princeton.edu staging application:remove_from_nginx
desc "Marks the server(s) to be removed from the loadbalancer"
task :remove_from_nginx do
  count = 0
  on roles(:app) do
    count += 1
  end
  raise "You must run this command on individual servers utilizing the --hosts= switch" if count > (roles(:app).length / 2)
  on roles(:app) do
    within release_path do
      execute :touch, "public/remove-from-nginx"
    end
  end
end
# You can/ should apply this command to a subset of hosts
# cap --hosts=lib-jobs-staging2.lib.princeton.edu staging application:serve_from_nginx
desc "Marks the server(s) to be added back to the loadbalancer"
task :serve_from_nginx do
  on roles(:app) do
    within release_path do
      execute :rm, "-f public/remove-from-nginx"
    end
  end
end

before "deploy:reverted", "deploy:assets:precompile"
# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
set :linked_dirs, %w[open_marc_records subversion_eads gitlab_eads]

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :yarn_flags, '--silent --no-progress'

set :whenever_roles, -> { [:cron_prod1, :cron_prod2, :cron_staging2] }
