namespace :selenium do
  desc 'Runs server for selenium tests'
  task :servers do
    `echo 'Starting app server and selenium server' & ./script/server -e selenium -p 7000 & selenium`
  end

  desc 'Runs selenium tests'
  Rake::TestTask.new(:test => :kill_firefox) do |t|
    t.libs << "test"
    t.pattern = 'test/selenium/**/*_test.rb'
    t.verbose = true
  end

  desc 'Kills firefox before runnig selenium'
  task :kill_firefox do
    if find_pid_of_process('firefox') != 0
      `skill firefox`
    end
  end

  #FIXME: This method is created for Object...
  def find_pid_of_process(name)
    `ps ux | awk '/#{name}/ && !/awk/ {print $2}'`.to_i
  end

end



