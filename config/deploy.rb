# config valid for current version and patch releases of Capistrano
lock "~> 3.19.2"

set :application, "FileBird"
set :repo_url, "git@github.com:WPR-Engineering/FileBird.git"
#set :branch, 'master'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/FileBird"

# Default value for :format is :airbrussh.
# set :format, :airbrussh
set :format, :pretty
set :rails_env, "production"
set :rvm_type, :auto
set :rvm_ruby_version, '3.1.6'
#set :rvm_custom_path, '/home/deployer/.rvm'


set :log_level, :debug


set :use_sudo, false

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
#append :linked_files, "config/database.yml"
set :linked_files, %w{config/database.yml config/secrets.yml}

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
#set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')
#set :linked_files, fetch(:linked_files, []).push('config/database.yml')
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/downloads Mounts/PRX Mounts/Backup}


#SSHKit.config.command_map[:sidekiq] = "bundle exec sidekiq"
#SSHKit.config.command_map[:sidekiqctl] = "bundle exec sidekiqctl"
#set :init_system, :upstart
#set :upstart_service_name, 'sidekiq'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
