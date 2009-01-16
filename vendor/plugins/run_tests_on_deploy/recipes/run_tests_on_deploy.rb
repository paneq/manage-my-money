# == Synopsis
#
# This plug-in is a Capistrano extension.  It requires Capistrano 2.0.0 or greater.
#
# The plugin adds the following tasks:
#   deploy:run_tests
#   deploy:without_tests
#
# Once installed, running
#   cap deploy
# will run all of your tests before doing the final symlink.  If the tests fail, the 
# symlink will not be created and your deployment will roll back.
#
# == Details
#
# The deploy:run_tests task is executed before the symlink
# task.  The run_tests task does the following:
# * prepares your test db with rake db:test:prepare
# * runs all of your tests with "rake test" at a nice level of -10
# The deploy:run_tests tasks won't work if you call it by itself, as it runs from the
# release_path directory, which won't exist unless called after deploy:update_code.
#
# to deploy without tests:
#   cap deploy:without_tests  
#  
# you can also set the run_tests option to 0 from the command line like this:
#   cap -S run_tests=0 deploy
# this allows you to do things like deploying with migrations but without tests:
#   cap -S run_tests=0 deploy:migrations
#
# The original idea for the :run_tests task is from
# http://blog.testingrails.com/2006/9/4/running-tests-on-deploy-with-capistrano,
# which, sadly, seems to be defunct.
#
# == Installation
#
# === Plugin installation
#
# You should be able to install with the following command (from rails root):
#   script/plugin install run_tests_on_deploy
#
# If that doesn't work, try running
#   script/plugin discover
# and then
#   script/plugin install run_tests_on_deploy
#
# If *that* doesn't work, try
#   script/plugin install svn://svn.spattendesign.com/svn/plugins/run_tests_on_deploy
#
# If that doesn't work, send me an e-mail at mailto:scott@spattendesign.com
#
# === Capistrano configuration
#
# This plugin requires Capistrano 2.0.0 or greater.
# To upgrade to the latest version (currently 2.1.0)
#   gem install capistrano
#
# Once the plug-in is installed, make sure that the recipes are seen by Capistrano
#   cap -T | grep deploy:without_tests
# should return
#   cap deploy:without_tests          # deploy without running tests
# If capistrano is not seeing the deploy:without_tests task, then you need to update your Capfile.
#
# (The following is from Jamis Buck, in http://groups.google.com/group/capistrano/browse_thread/thread/531ad32aff5fe5a8)
#
# In Capistrano 2.1.0 or above:
# you can delete your Capify file in rails root, and then, from rails root, run
#   capify .
#
# If you do not want to delete your Capify file, or if you are using Capistrano 2.0.0, add the following line to your Capify file:
#   Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
#
# == Contact Info
#
# This plug-in was written by Scott Patten of spatten design.  The original post announcing the plug-in was at
# http://spattendesign.com/2007/10/19/running-tests-on-deploy
#
# Website:: http://spattendesign.com
# Blog:: http://spattendesign.com/blog
# email:: mailto:scott@spattendesign.com
# 
# == Change Log
#
#   Scott Patten [2007-08-01]: creation
#   Scott Patten [2007-10-14]: updated to Capistrano 2.0 
#   Scott Patten [2007-10-17]: plugin-ized the recipe
#   Scott Patten [2007-10-17]: cleaned up documentation and formatted it for rdoc

before "deploy:symlink", "deploy:run_tests"

namespace :deploy do
  desc "Run the full tests on the deployed app.  To deploy without tests, try" +
       " cap deploy:without_tests or cap -S run_tests=0 deploy" 
  task :run_tests do
   unless fetch(:run_tests, "1") == "0"     
     run "cd #{release_path} && rake db:test:prepare" 
     run "cd #{release_path} && nice -n 5 rake db:migrate && nice -n 5 rake test" #Changed by rupert so tests are not run against production database but by test database in another environment than developers have. Also priorite of task changed to 5 so it goes a bit faster.
   end
  end

  desc "deploy without running tests"
  task :without_tests do
    set(:run_tests, "0")
    deploy.default
  end  
end
