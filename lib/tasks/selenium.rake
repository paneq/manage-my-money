namespace :db do
  namespace :migrate do
    desc 'Migrates development and selenium databases and clones structure for tests'
    task :all do
      puts `rake db:migrate`
      puts `rake db:test:clone_structure`
      puts `rake db:migrate RAILS_ENV=selenium`
    end
  end
end

namespace :selenium do
  desc 'Runs server for selenium tests'
  task :servers do
    `echo 'Starting app server and selenium server' & ./script/server -e selenium -p 3031 & selenium`
  end

  desc 'Runs selenium test'
  Rake::TestTask.new(:test) do |t|
      t.libs << "test"
      t.pattern = 'test/selenium/**/*_test.rb'
      t.verbose = true
  end
end



