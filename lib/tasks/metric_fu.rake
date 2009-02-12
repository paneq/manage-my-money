require 'metric_fu'
require 'rcov'
require 'rcov/rcovtask'

MetricFu::Configuration.run do |config|
  #     config.metrics          = [:coverage, :flog]
  #     config.churn    = { :start_date => lambda{ 3.months.ago } }
#        config.coverage = { :test_files => ['test/functional/*_test.rb','test/integration/*_test.rb','test/unit/*_test.rb'],
#                  :rcov_opts => ["--sort coverage", "--html", "--rails ", "--exclude /rubygems/,/gems/,/Library/"] }
  config.coverage = { :test_files => ['test/selenium/*_test.rb'],
    :rcov_opts => ["--sort coverage", "--html", "--rails ", "--exclude /rubygems/,/gems/,/Library/"] }
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
    config_coverage_selenium = { :test_files => ['test/selenium/*_test.rb'],
      :rcov_opts => ["--aggregate coverage.data", "--sort coverage", "--html", "--rails ", "--exclude /rubygems/,/gems/,/Library/"] }

    desc "Generate and open coverage report for normal tests and selenium"
    task :all => [:remove_state, :do_normal, :do_selenium] do
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

    desc "RCov task to generate report"
    Rcov::RcovTask.new(:do_selenium => 'clean') do |t|
      FileUtils.mkdir_p(MetricFu::BASE_DIRECTORY) unless File.directory?(MetricFu::BASE_DIRECTORY)
      t.test_files = FileList[*config_coverage_selenium[:test_files]]
      t.rcov_opts = config_coverage_selenium[:rcov_opts]
      t.output_dir = COVERAGE_DIR
      # this line is a fix for Rails 2.1 relative loading issues
      t.libs << 'test'
    end

    task :remove_state do
      `rm -f coverage.data`
    end


  end
end