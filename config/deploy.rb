set :application, "manage_my_money"
set :repository,  "svn+ssh://rupert@s.rootnode.pl/home/rupert/svn/manage_my_money/code"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/rupert/apps/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :subversion

set :user, "rupert"
set :use_sudo, false
set :group_writable, false

role :app, "s.rootnode.pl"
role :web, "s.rootnode.pl"
role :db,  "s.rootnode.pl", :primary => true


desc 'Change all files in latest release to be unreadible and unexecutable by people from same group and others'
task :chmod_files do
  run "chmod -R go= #{release_path}"
end

task :show_var do
  run "ruby --version"
  run "gem --version"
  run "rake --version"
  run "gem list"
  run "echo $GEM_HOME"
  run "echo $GEM_PATH"
  run "echo $PATH"
end

namespace :backgroundrb do
  desc "stop the backgroundrb server"
  task :stop, :roles => :app do
    invoke_command "sh -c 'if [ -a #{current_path}/log/backgroundrb_2000.pid ]; then #{current_path}/script/backgroundrb stop; fi;'", :via => run_method
  end

  desc "start the backgroundrb server"
  task :start, :roles => :app do
    invoke_command "nohup #{current_path}/script/backgroundrb start -d", :via => run_method
  end

  desc "restart the backgroundrb server"
  task :restart, :roles => :app do
    deploy.backgroundrb.stop
    deploy.backgroundrb.start
  end
end


namespace :sphinx do
  desc "Updates links to sphinx indexes which are in shared directory"
  task :update_symlink do
    run <<-CDM
      rm -rf #{latest_release}/db/sphinx &&
      mkdir -p #{latest_release}/db/sphinx &&
      ln -s #{shared_path}/sphinx/production #{latest_release}/db/sphinx/production &&
      ln -s #{shared_path}/sphinx/development #{latest_release}/db/sphinx/development &&
      ln -s #{shared_path}/sphinx/test #{latest_release}/db/sphinx/test
    CDM
  end

  desc "Builds a new index for sphinx (for production)"
  task :index do
    run "cd #{latest_release} && rake ts:index RAILS_ENV=production"
  end
end

before "deploy:finalize_update", :show_var
after "deploy:finalize_update", :chmod_files

after "deploy:finalize_update", "sphinx:update_symlink"

after "deploy", "deploy:cleanup"
after "deploy:migrations", "deploy:cleanup"

