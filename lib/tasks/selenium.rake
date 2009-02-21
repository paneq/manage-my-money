namespace :db do
  namespace :migrate do
    desc 'Migrates development and selenium databases and clones structure for tests and do annotate models'
    task :all do
      Rake::Task['db:migrate'].invoke
      Rake::Task['db:test:clone_structure'].invoke
      puts `rake db:migrate RAILS_ENV=selenium` #no other way to change Rails_ENV while running  rake
      Rake::Task['annotate_models'].invoke
    end
  end
end

namespace :selenium do
  desc 'Runs server for selenium tests'
  task :servers do
    `echo 'Starting app server and selenium server' & ./script/server -e selenium -p 3031 & selenium`
  end

  desc 'Runs selenium tests'
  Rake::TestTask.new(:test => :kill_firefox) do |t|
      t.libs << "test"
      t.pattern = 'test/selenium/**/*_test.rb'
      t.verbose = true
  end

  desc 'Kills firefox before runnig selenium'
  task :kill_firefox do
      @killed_firefox = false
      if find_pid_of_process('firefox') != 0
        `skill firefox`
        @killed_firefox = true
      end
    end

end



