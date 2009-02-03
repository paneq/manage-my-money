require 'metric_fu'

MetricFu::Configuration.run do |config|
#     config.metrics          = [:coverage, :flog]
#     config.churn    = { :start_date => lambda{ 3.months.ago } }
      config.coverage = { :test_files => ['test/functional/*_test.rb','test/integration/*_test.rb','test/unit/*_test.rb'],
                :rcov_opts => ["--sort coverage", "--html", "--rails ", "--exclude /rubygems/,/gems/,/Library/"] }
      config.flog     = { :dirs_to_flog => ['cms/app', 'cms/lib']  }
      config.flay     = { :dirs_to_flay => ['cms/app', 'cms/lib']  }
      config.saikuro  = { "--warn_cyclo" => "3", "--error_cyclo" => "4" }
end

#do not work
#namespace 'metrics' do
#  ENV['CC_BUILD_ARTIFACTS'] = 'stats/metric_fu'
#end