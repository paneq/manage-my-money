ENV["RAILS_ENV"] = "selenium"

require 'test_helper'

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'

begin

  require 'selenium'

  class TransfersAndAutocompleteTest < Test::Unit::TestCase
    self.use_transactional_fixtures = false

    def setup
      selenium_setup
      save_currencies
      save_rupert
      log_rupert
      @selenium.set_context("Transfers Test")
    end


    def test_on_transfers_site
      begin
        Rake::Task['ts:in'].invoke
        Rake::Task['ts:start'].invoke
        puts 'Here comes the test'
      ensure
        Rake::Task['ts:stop'].invoke
      end
    end

    
    def teardown
      @selenium.stop unless $selenium
      assert_equal [], @verification_errors
      @selenium = nil
      Test::Unit::TestCase.use_transactional_fixtures = true
    end

  end

end unless TEST_ON_STALLMAN