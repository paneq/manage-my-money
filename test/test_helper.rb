ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
  include AuthenticatedTestHelper
  
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  def save_rupert
    @rupert = User.new()
    @rupert.active = true
    @rupert.email = 'email@example.com'
    @rupert.login = 'rupert_XYZ_ab'
    @rupert.password = @rupert.login
    @rupert.password_confirmation = @rupert.login
    @rupert.transaction_amount_limit_type = :actual_month
    @rupert.save!
    @rupert.activate!
  end

  def make_currencies
    @zloty = Currency.new(:symbol => 'zl', :long_symbol => 'PLN', :name => 'Złoty', :long_name =>'Polski złoty')
    @dolar = Currency.new(:symbol => '$', :long_symbol => 'USD', :name => 'Dolar', :long_name =>'Dolar amerykańcki')
    @euro = Currency.new(:symbol => '€', :long_symbol => 'EUR', :name => 'Euro', :long_name =>'Europejckie euro')
    @currencies = [@zloty, @euro, @dolar]
  end

  def save_currencies
    make_currencies unless @currencies
    @currencies.each {|currency| currency.save!}
  end

  def log_rupert
    @request.session[:user_id] = @rupert.id
  end
end
