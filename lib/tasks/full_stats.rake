require 'socket'

namespace :stats do
  desc 'Saves full stats of project based on every svn revision number'
  task :full do
    
    #settings
    start_rev = 226
    end_rev = 311
    machine_name = Socket.gethostname
    case machine_name
    when 'arachno'
      settings_file = '/home/jarek/NetBeansProjects/stats/file'
      dir = '/home/jarek/NetBeansProjects/stats/code'
    else
      settings_file = '/media/data/develop/rails/3m/svn/stats/file'
      dir = '/media/data/develop/rails/3m/svn/stats/code'
    end
    #end
    previous_directory = Dir.getwd
    begin
      Dir.chdir dir
      puts `pwd`
      puts `ls -al`
      Range.new(start_rev, end_rev).each do |rev|
        `svn update -r #{rev}`
        `svn update lib/tasks/rspec.rake` #to newest version so it does not change rake stats task
        `echo REV: #{rev} >> #{settings_file}`
        `rake stats >> #{settings_file}`
        Kernel.print '.'
      end
      puts ''
    ensure
      Dir.chdir previous_directory
    end
  end
end
