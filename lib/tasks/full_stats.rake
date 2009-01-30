namespace :stats do
  desc 'Saves full stats of project based on every svn revision number'
  task :full do
    
    #settings
    start_rev = 4
    end_rev = 215
    settings_file = '/media/data/develop/rails/3m/svn/stats/file'
    #end
    previous_directory = Dir.getwd
    begin
      Dir.chdir '/media/data/develop/rails/3m/svn/stats/code'
      puts `pwd`
      puts `ls -al`
      Range.new(start_rev, end_rev).each do |rev|
        `svn update -r #{rev}`
        `echo REV: #{rev} >> #{settings_file}`
        `rake stats >> #{settings_file}`
        puts '.'
      end
    ensure
      Dir.chdir previous_directory
    end
  end
end
