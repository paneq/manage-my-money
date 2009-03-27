require 'socket'
namespace :stats do
  namespace :full do
    desc 'Saves full stats of project based on every svn revision number'
    task :parse do

      machine_name = Socket.gethostname
      case machine_name
      when 'arachno'
        #FIXME: Make this a paramter to task
        settings_file = '/home/jarek/NetBeansProjects/stats/file'
        to_file = 'home/jarek/NetBeansProjects/stats/like_calc'
      else
        settings_file = '/media/data/develop/rails/3m/svn/stats/file'
        to_file = '/media/data/develop/rails/3m/svn/stats/like_calc'
      end
      

      #chm fut
      #chml fut
      types = %w[Controllers Helpers Models Libraries IntegrationTests FunctionalTest UnitTests Total]
      measure = %w[LOC Classes Methods]
      begin
        #f = File.new(to_file)
        rev = nil
        Kernel.print "RevisionNumber\t"
        types.each do |type|
          measure.each do |m|
            Kernel.print "#{type+m}\t"
          end
        end
        Kernel.puts
        File.open(settings_file).each do |line|


          #data
          md = /\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)/.match(line)
          if md 
            next if md[1] =~ /Name/
            
            if md[1] =~ /Controllers/
              Kernel.puts
              Kernel.print "#{rev}\t"
            end

            [['LOC',2],['Classes',3],['Methods',4]].each do |name, numer|
              Kernel.print "#{md[numer].strip}\t"
            end

            if rev < 20 and md[1] =~ /Models/
              6.times { Kernel.print "0\t"}
            end

            if rev < 70 and md[1] =~ /Libraries/
              3.times { Kernel.print "0\t"}
            end
          end

          #Revision
          md = /REV: (\d+)/.match(line)
          if md
            rev = md[1].to_i
            next
          end

        end
        #f.close
      ensure
        
      end
    end
  end
end