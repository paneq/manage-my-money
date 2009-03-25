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

set :shared_children,   %w(system log pids backup sphinx config)

desc 'Change all files in latest release to be unreadible and unexecutable by people from same group and others'
task :chmod_files do
  run "chmod -R go= #{release_path}"
end

desc 'Copies files from shared/config to app/config. Ex: site_keys.yml, database.yml, sphinx.yml'
task :copy_config do
  run "cp #{shared_path}/config/*.yml #{release_path}/config/"
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

namespace :backup do
  desc 'Creates production database dump and makes a backup using rootnode backup system'
  task :database do
    db_backup_path = "#{shared_path}/backup/db"
    backup_name = '3mp_db_backup'
    run "mkdir -p #{db_backup_path}"
    run "cd #{latest_release} && rake backup:database backup_path=#{db_backup_path} RAILS_ENV=production"
    run "chmod -R 700 #{shared_path}/backup"
    run "ls -al #{db_backup_path}"
    run "backup #{db_backup_path} #{backup_name}"
    run "backup --remove-older-than 1M #{backup_name}"
    run "backup -s #{backup_name}"
  end

  desc 'Creates production sphinx indexes backup'
  task :sphinx_indexes do
    backup_path = "#{shared_path}/sphinx"
    backup_name = "3mp_sphinx_backup"
    run "backup #{backup_path} #{backup_name}"
    run "backup --remove-older-than 1M #{backup_name}"
    run "backup -s #{backup_name}"
  end


  desc 'Creates all releases backup'
  task :releases do
    backup_path = "#{releases_path}"
    backup_name = "3mp_releases_backup"
    run "backup #{backup_path} #{backup_name}"
    run "backup --remove-older-than 1M #{backup_name}"
    run "backup -s #{backup_name}"
  end

  desc 'Creates ruby, rails, gems, rake backup'
  task :binaries do
    dirs = %w(binary railsgems)
    dirs.each do |name|
      backup_path = "/home/rupert/#{name}"
      backup_name = "3mp_files_#{name}"
      run "backup #{backup_path} #{backup_name}"
      run "backup --remove-older-than 1M #{backup_name}"
      run "backup -s #{backup_name}"
    end
  end
end


before "deploy:finalize_update", :show_var
after "deploy:finalize_update", :copy_config
after "deploy:finalize_update", :chmod_files

after "deploy:finalize_update", "sphinx:update_symlink"

after "deploy:finalize_update", 'backup:releases'

before "deploy:migrate", 'backup:database'
before "deploy:migrate", 'backup:sphinx_indexes'

after "deploy", "deploy:cleanup"
after "deploy:migrations", "deploy:cleanup"

