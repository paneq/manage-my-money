require 'metric_fu'
require 'rcov'
require 'rcov/rcovtask'

module MetricFu
  BASE_DIRECTORY = 'stats/metric_fu'
end

MetricFu::Configuration.run do |config|
#  config.metrics          = [:churn, :flog, :flay, :saikuro, :reek, :roodi]
#  config.churn    = { :start_date => lambda{ 3.months.ago } }
  #        config.coverage = { :test_files => ['test/functional/*_test.rb','test/integration/*_test.rb','test/unit/*_test.rb'],
  #                  :rcov_opts => ["--sort coverage", "--html", "--rails ", "--exclude /rubygems/,/gems/,/Library/"] }
  #  config.coverage = { :test_files => ['test/selenium/*_test.rb'],
  #    :rcov_opts => ["--sort coverage", "--html", "--rails ", "--exclude /rubygems/,/gems/,/Library/"] }
  config.flog     = { :dirs_to_flog => ['cms/app', 'cms/lib']  }
  config.flay     = { :dirs_to_flay => ['cms/app', 'cms/lib']  }
  config.saikuro  = { "--warn_cyclo" => "3", "--error_cyclo" => "4" }
end

#do not work
#namespace 'metrics' do
#  ENV['CC_BUILD_ARTIFACTS'] = 'stats/metric_fu'
#end



namespace :metrics do
  namespace :coverage do
    COVERAGE_DIR = File.join(MetricFu::BASE_DIRECTORY, 'coverage')
    config_coverage_normal = { :test_files => ['test/functional/*_test.rb','test/integration/*_test.rb','test/unit/*_test.rb'],
      :rcov_opts => ["-t", "--no-html", "--aggregate coverage.data", "--sort coverage", "--rails ", "--exclude /rubygems/,/gems/,/Library/"] }

    desc "Generate and open coverage report for normal tests and selenium"
    task :all => [:remove_state, :do_normal, :do_selenium, :remove_state] do
      puts 'all'

    end

    desc "RCov task to generate report"
    Rcov::RcovTask.new(:do_normal => 'clean') do |t|
      FileUtils.mkdir_p(MetricFu::BASE_DIRECTORY) unless File.directory?(MetricFu::BASE_DIRECTORY)
      t.test_files = FileList[*config_coverage_normal[:test_files]]
      t.rcov_opts = config_coverage_normal[:rcov_opts]
      t.output_dir = COVERAGE_DIR
      # this line is a fix for Rails 2.1 relative loading issues
      t.libs << 'test'
    end


    task :do_selenium => [:kill_firefox] do
      if fork.nil?
        #child
        exec("rcov script/server -o #{COVERAGE_DIR} --aggregate coverage.data --sort coverage --html --rails --exclude /rubygems/,/gems/,/Library/,/config\/boot.rb/ -- -e selenium -p 3031")
      else
        #parent
        sleep 15
        Rake::Task['selenium:test'].invoke
        rcov_pid = find_pid_of_process('ruby.*rcov.*selenium.*3031')
        Process.kill 'TERM', rcov_pid
      end
    end

    

    desc 'Kills firefox before runnig selenium'
    task :kill_firefox do
      @killed_firefox = false
      if find_pid_of_process('firefox') != 0
        `skill firefox`
        @killed_firefox = true
      end
    end


    #not used
    task :resume_firefox do
      if (find_pid_of_process('firefox') == 0) && @killed_firefox
        exec('firefox 2> /dev/null 1> /dev/null') if fork.nil?
      end
    end

    task :remove_state do
      `rm -f coverage.data`
    end


    def find_pid_of_process(name)
      `ps ux | awk '/#{name}/ && !/awk/ {print $2}'`.to_i
    end


  end
end