require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'
require 'active_record'


plugin_test_dir = File.dirname(__FILE__)
require plugin_test_dir + '/../init.rb'

ActiveRecord::Base.logger = Logger.new(plugin_test_dir + "/debug.log")
ActiveRecord::Base.configurations = YAML::load(IO.read(plugin_test_dir + "/db/database.yml"))
ActiveRecord::Base.establish_connection("sqlite3mem")
ActiveRecord::Migration.verbose = false
load(File.join(plugin_test_dir, "db", "schema.rb"))