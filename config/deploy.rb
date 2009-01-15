set :application, "manage_my_money"
set :repository,  "svn://3m.dev.pankowecki.pl:3033"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/rupert/apps/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :subversion

set :user, "rupert"
set :scm_username, "rupert"
set :use_sudo, false

role :app, "s.rootnode.pl"
role :web, "s.rootnode.pl"
role :db,  "s.rootnode.pl", :primary => true
