namespace :config do
  desc 'Saves full stats of project based on every svn revision number'
  task :copy do
    #FIXME: Make parameter for source pwd with default option
    puts `cp -v ../config/*.yml config/`
    puts `cp -v ../config/deploy.rb config/`
  end
end