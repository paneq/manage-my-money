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
  run "echo $GEM_HOME"
  run "echo $GEM_PATH"
  run "echo $PATH"
  run "chmod -R go= #{latest_release}"
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


after "deploy:symlink", :chmod_files
