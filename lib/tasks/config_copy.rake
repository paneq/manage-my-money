namespace :config do
  desc 'Saves full stats of project based on every svn revision number'
  task :copy do
    puts `cp -v ../config/*.yml config/`
  end
end