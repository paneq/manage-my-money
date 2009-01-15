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
  run "chmod -R go= #{latest_release}"
end

after "deploy:symlink", :chmod_files
