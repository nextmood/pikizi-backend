# see http://www.zorched.net/2008/06/17/capistrano-deploy-with-git-and-passenger/
default_run_options[:pty] = true
set :application, "pikizi"

set :deploy_to, "/var/rails/#{application}"

set :scm, "git"
set :repository, "git@github.com:nextmood/pikizi-backend.git" 

set :branch, "master"
set :deploy_via, :remote_cache

set :domain, "wikismo.com"

set :user, "fpatte"

#set :ssh_options, { :forward_agent => true }

role :app, domain                     # your app-server here
role :web, domain                     # your web-server here
role :db,  domain, :primary => true   # your db-server here

=begin
before "deploy:start" do 
  run "#{current_path}/script/ferret_server -e production start"
end 
 
after "deploy:stop" do 
  run "#{current_path}/script/ferret_server -e production stop"
end
 
after 'deploy:restart' do
  run "cd #{current_path} && ./script/ferret_server -e production stop"
  run "cd #{current_path} && ./script/ferret_server -e production start"
end
=end

# create the link toward the shared resources
task :after_update_code do
  %w{uploaded_photos index}.each do |share|
    run "ln -s #{shared_path}/#{share} #{release_path}/#{share}"
  end
end


namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails (passenger)"
    task t, :roles => :app do ; end
  end
end
