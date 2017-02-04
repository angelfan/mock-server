require 'mina/rails'
require 'mina/git'
require 'mina/bundler'
require 'mina/puma'
require 'mina/rvm'

# overwrite pumactl_socket
namespace :puma do
  set :pumactl_socket, '/srv/www/mock-server/shared/tmp/sockets/mock-server.sock'
end

set :domain, 'deploy@139.162.117.170'
set :deploy_to, '/srv/www/mock-server'
set :repository, 'git@github.com:angelfan/mock-server.git'
set :branch, 'master'

shared_dirs = %w(log public/uploads tmp/pids tmp/sockets)
set :shared_dirs, fetch(:shared_dirs, []).push(*shared_dirs)

shared_files = %w(config/database.yml config/secrets.yml)
set :shared_files, fetch(:shared_files, []).push(*shared_files)

task :environment do
  invoke :'rvm:use', File.read('.ruby-version').strip
end

task setup: :environment do
  # config
  command %(mkdir -p "#{fetch(:deploy_to)}/shared/config")
  command %(chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/config")
  command %(touch "#{fetch(:deploy_to)}/shared/config/database.yml")
  command %(touch "#{fetch(:deploy_to)}/shared/config/secrets.yml")
  command %(echo "-----> Be sure to edit '#{fetch(:deploy_to)}/shared/config/database.yml'.")
  command %(echo "-----> Be sure to edit '#{fetch(:deploy_to)}/shared/config/secrets.yml'.")

  # puma
  command %(touch "#{fetch(:deploy_to)}/shared/config/puma.rb")
  command %(echo "-----> Be sure to edit 'shared/config/puma.rb'.")
  command %(mkdir -p "#{fetch(:deploy_to)}/shared/tmp/pids")
  command %(chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/tmp/pids")
  command %(mkdir -p "#{fetch(:deploy_to)}/shared/tmp/sockets")
  command %(chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/tmp/sockets")
  command %(touch "#{fetch(:deploy_to)}/shared/tmp/sockets/puma.state")
  command %(echo "-----> Be sure to edit 'shared/tmp/sockets/puma.state'.")
  command %(touch "#{fetch(:deploy_to)}/shared/log/puma.stdout.log")
  command %(echo "-----> Be sure to edit 'shared/log/puma.stdout.log'.")
  command %(touch "#{fetch(:deploy_to)}/shared/log/puma.stderr.log")
  command %(echo "-----> Be sure to edit 'shared/log/puma.stderr.log'.")

  # log
  command %(mkdir -p "#{fetch(:deploy_to)}/shared/log")
  command %(chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/log")
end

desc 'Deploys the current version to the server.'
task deploy: :environment do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      invoke :'puma:phased_restart'
    end
  end
end

#  - https://github.com/mina-deploy/mina/tree/master/docs
