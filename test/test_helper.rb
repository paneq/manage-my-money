ENV["RAILS_ENV"] = "test" unless ENV["RAILS_ENV"] == 'selenium'

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require File.expand_path(File.dirname(__FILE__) + "/autocomplete_test_helper")
require 'test_help'

# stallman cannot run selenium test :-)
TEST_ON_STALLMAN = (Socket.gethostname == 'stallman.rootnode.net')

# Code for manipulating actual time in tests (from http://www.ruby-forum.com/topic/114087#267920)
class Date
  @@forced_today = nil
  class << self
    alias :unforced_today :today
    def today
      return @@forced_today ? @@forced_today : unforced_today
    end
    def forced_today=(now)
      @@forced_today = now
    end
  end
end

class Time
  @@forced_now = nil
  class << self
    alias :unforced_now :now
    def now
      return @@forced_now ? @@forced_now : unforced_now
    end
    def forced_now=(now)
      @@forced_now = now
    end
  end
end
#end of actual date manipulation code



class ActiveSupport::TestCase
  include AuthenticatedTestHelper
  include ::AutocompleteTestHelper
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

  fixtures :currencies

  def save_rupert
    prepare_currencies
    @rupert = User.new()
    @rupert.email = 'email@example.com'
    @rupert.login = 'rupert_xyz'
    @rupert.password = @rupert.login
    @rupert.password_confirmation = @rupert.login
    @rupert.transaction_amount_limit_type = :this_month
    @rupert.multi_currency_balance_calculating_algorithm = :show_all_currencies
    @rupert.default_currency = @zloty
    @rupert.invert_saldo_for_income = false
    @rupert.save!
    @rupert.activate!
    @selenium.set_context("Save rupert") if @selenium
  end


  def save_jarek
    prepare_currencies
    @jarek = User.new()
    @jarek.email = 'jarek@example.com'
    @jarek.login = 'jarek_xyz'
    @jarek.password = @jarek.login
    @jarek.password_confirmation = @jarek.login
    @jarek.transaction_amount_limit_type = :this_month
    @jarek.multi_currency_balance_calculating_algorithm = :show_all_currencies
    @jarek.default_currency = @zloty
    @jarek.invert_saldo_for_income = false
    @jarek.save!
    @jarek.activate!
  end


  def prepare_currencies
    (@selenium ? make_currencies : fixture_currencies) unless @currencies
  end

  
  def make_currencies
    @zloty = Currency.create!(:symbol => 'zl', :long_symbol => 'PLN', :name => 'Złoty', :long_name =>'Polski złoty')
    @dolar = Currency.create!(:symbol => '$', :long_symbol => 'USD', :name => 'Dolar', :long_name =>'Dolar amerykański')
    @euro = Currency.create!(:symbol => 'E', :long_symbol => 'EUR', :name => 'Euro', :long_name =>'Europejckie euro')
    @currencies = [@zloty, @euro, @dolar]
  end


  def fixture_currencies
    @zloty = currencies(:zloty)
    @dolar = currencies(:dolar)
    @euro = currencies(:euro)
    @currencies = [@zloty, @euro, @dolar]
  end


  def log_rupert
    log_user(@rupert)
  end


  def log_user(user)
    if @selenium
      @selenium.open "/login"
      @selenium.type "login", user.login
      @selenium.type "password", user.login
      @selenium.click "remember_me"
      @selenium.click "commit"
      @selenium.wait_for_page_to_load "10000"
      assert_equal "Witamy w serwisie.", @selenium.get_text("flash_notice")
    else
      @request.session[:user_id] = user.id
    end
  end


  def rupert
    return @rupert
  end

  
  def add_category_options(user, report)
    user.categories.each do |c|
      report.category_report_options << CategoryReportOption.new({:category => c, :inclusion_type => :both})
    end
  end


  def make_simple_transfer(options = {})
    save_rupert if options[:user].nil? and @rupert.nil?
    hash = {:day => 1.day.ago.to_date, :description =>'empty', :user => @rupert, :currency => @zloty, :value => 100, :income => @rupert.try(:expense), :outcome => @rupert.try(:asset) }
    hash.merge! options

    transfer = Transfer.new(:user => hash[:user])
    transfer.day = hash[:day]
    transfer.description = hash[:description]
    transfer.import_guid = hash[:import_guid]

    transfer.transfer_items << TransferItem.new(
      :category => hash[:income],
      :currency => hash[:currency],
      :description => hash[:description],
      :value => hash[:value],
      :import_guid => hash[:import_guid]
    )

    transfer.transfer_items << TransferItem.new(
      :category => hash[:outcome],
      :currency => hash[:currency],
      :description => hash[:description],
      :value => -1*hash[:value],
      :import_guid => hash[:import_guid]
    )
    return transfer
  end


  # Save simple transfer with one currency, description and value <br />
  # Posssible options are: <br />
  # * day
  # * description
  # * user
  # * currency
  # * value
  # * income
  # * outcome
  def save_simple_transfer(options = {})
    transfer = make_simple_transfer(options)
    transfer.save!
    return transfer
  end


  # Returns currency with OK fieldsif no options given.
  # Options overrieds currency fields
  def make_currency(options = {})
    save_rupert if options[:user].nil? and @rupert.nil?
    default = {:name =>'new', :long_name => 'new new new currency', :symbol => 'cr', :long_symbol => 'SYM', :user => @rupert}
    default.merge!(options)
    return Currency.new(default)
  end

  # Saves currency with given options for overriding default fields
  def save_currency(options = {})
    currency = make_currency(options)
    currency.save!
    return currency
  end




  def assert_tab(menu_items, name)
    name = name.to_s
    assert_select 'div#bottom-menu' do
      assert_select "div#kind-of-#{name}"
      assert_select "div#kind-of-#{name} > div", menu_items.size

      menu_items.each_with_index do |menu_type, menu_nr|
        assert_select "div#kind-of-#{name}-#{menu_type}"

        menu_items.size.times do |item_nr|
          assert_select "div#kind-of-#{name}-#{menu_type} div:nth-child(#{item_nr+1})" do
            klass = menu_nr == item_nr ? 'active-tab' : 'inactive-tab'
            assert_select "td[class~=#{klass}]"
          end
        end

      end

    end
  end


  def assert_transfer_pages(action)
    assert_select 'div#bottom-menu' do
      assert_select 'div#show-transfer' do
        assert_select 'div#show-transfer-full'
        assert_select 'div#show-transfer-search' do
          assert_select "form[method=post][action=#{action}]" do
            assert_select 'p#transfer-day-period' do
              assert_select 'label'
              assert_select 'select[name=transfer_day_period]' do
                assert_select 'option[value=SELECTED]'
                assert_select 'option[value=THIS_DAY]'
              end
            end
            ['start', 'end'].each do |time|
              assert_select "p\#transfer-day-#{time}" do
                ['year', 'month', 'day'].each do |period|
                  #assert_select "select[name~=#{period}]"
                end
                assert_select 'select', 3
              end
            end
          end
        end
      end

    end
  end


  def require_memcached
    unless `ps aux` =~ Regexp.new("memcached.*-p #{MEMCACHED_PORT}")
      `memcached -d -p #{MEMCACHED_PORT}`
    end

    assert_match(/memcached.*-p #{MEMCACHED_PORT}/, `ps aux`)
  end

  
  def create_share_report(user, save = true)
    r = ShareReport.new
    r.user = user
    r.category = user.categories.first
    r.report_view_type = :pie
    r.set_period(["10-01-2009".to_date, "17-01-2009".to_date, :LAST_WEEK])
    r.depth = 5
    r.max_categories_values_count = 6
    r.name = "Testowy raport"
    r.save! if save
    r
  end


  def create_flow_report(user)
    r = FlowReport.new
    r.user = user
    add_category_options user, r
    r.report_view_type = :text
    r.set_period(["10-01-2009".to_date, "17-01-2009".to_date, :LAST_WEEK])
    r.name = "Testowy raport"
    r.save!
    r
  end


  def create_value_report(user, save = true, category_options = true)
    r = ValueReport.new
    r.user = user
    add_category_options(user, r) if category_options
    r.report_view_type = :bar
    r.period_type = :SELECTED
    r.period_start = 5.month.ago
    r.period_end = Date.today.to_date
    r.period_division = :week
    r.name = "Testowy raport"
    r.save! if save
    r
  end


  # jarek
  #   asset
  #     test
  #       child1
  #       child2
  #   income
  #   expense
  #   loan
  #   balance
  #
  #

  def prepare_sample_catagory_tree_for_jarek
    parent1 = @jarek.asset
    category = Category.new(
      :name => 'test',
      :description => 'test',
      :user => @jarek,
      :parent => parent1
    )

    @jarek.categories << category
    @jarek.save!

    child1 = Category.new(
      :name => 'child1',
      :description => 'child1',
      :user => @jarek,
      :parent => category
    )

    child2 = Category.new(
      :name => 'child2',
      :description => 'child2',
      :user => @jarek,
      :parent => category
    )

    @jarek.categories << child1 << child2
    @jarek.save!

  end

  def prepare_sample_system_category_tree
    e = SystemCategory.create :name => 'Expenses', :category_type => :EXPENSE

    f = SystemCategory.create :name => 'Food', :category_type => :EXPENSE

    al = SystemCategory.create :name => 'Alcohol', :category_type => :EXPENSE

    dr = SystemCategory.create :name => 'Dairy Products', :category_type => :EXPENSE

    ch = SystemCategory.create :name => 'Cheese', :category_type => :EXPENSE

    yo = SystemCategory.create :name => 'Yoghurt', :category_type => :EXPENSE

    jf = SystemCategory.create :name => 'Junk Food', :category_type => :EXPENSE

    fr = SystemCategory.create :name => 'Fruits', :category_type => :EXPENSE

    c = SystemCategory.create :name => 'Clothes', :category_type => :EXPENSE

    ca = SystemCategory.create :name => 'Cash', :category_type => :ASSET
    
    loan = SystemCategory.create :name => 'Loan', :category_type => :LOAN

    f.move_to_child_of e
    al.move_to_child_of f
    dr.move_to_child_of f
    yo.move_to_child_of dr
    ch.move_to_child_of dr
    jf.move_to_child_of f
    fr.move_to_child_of f
    c.move_to_child_of e

    assert_equal 11, SystemCategory.count(:all)

  end



  def create_rupert_expenses_account_structure
    # EXPENSE -            [SELECTED]
    #         |- food      [EDITED]
    #            |- healthy
    #         |- house
    #            |- rent
    #         |- clothes

    @expense_category = @rupert.expense
    @loan_category = @rupert.loan

    @food = Category.new(
      :name => 'food',
      :parent => @expense_category,
      :user => @rupert
    )
    @house = Category.new(
      :name => 'house',
      :parent => @expense_category,
      :user => @rupert
    )
    @clothes = Category.new(
      :name => 'clothes',
      :parent => @expense_category,
      :user => @rupert
    )
    @healthy = Category.new(
      :name => 'healthy',
      :parent => @food,
      :user => @rupert
    )
    @rent = Category.new(
      :name => 'rent',
      :parent => @house,
      :user => @rupert
    )
    @rupert.categories << @food << @house << @clothes << @healthy << @rent
    @rupert.save!
    @rupert.categories(true) #very important!

    assert_equal @expense_category, @food.parent
    assert_equal @food, @healthy.parent
    assert_equal @expense_category, @house.parent
    assert_equal @house, @rent.parent
    assert_equal @expense_category, @clothes.parent
    categories_types = [@expense_category, @food, @house, @clothes, @healthy, @rent].map { |c| c.category_type}.uniq!
    assert_equal 1, categories_types.size
    assert_equal :EXPENSE, categories_types.first
  end


  TABLES = %w{transfer_items exchanges transfers category_report_options reports goals categories users currencies}
  def selenium_setup
    raise 'No selenium test on stallman' if TEST_ON_STALLMAN
    @verification_errors = []
    if $selenium
      @selenium = $selenium
    else
      @selenium = Selenium::SeleniumDriver.new("127.0.0.1", 4444, "*custom /usr/lib/firefox-3.0.8/firefox -p Selenium", "http://127.0.0.1:7000/", 10000);
      @selenium.start
    end
    

    #setup
    @selenium.open	"/selenium/setup?clear_tables=#{TABLES.join(',')}"
  end


  def selenium_teardown
    @selenium.open	"/selenium/setup?clear_tables=#{TABLES.join(',')}"
    @selenium.stop unless $selenium
    assert_equal [], @verification_errors
    @selenium = nil
  end

  
  # Yields a block of code and when Assertion Error is caught it is stored in @verification_errors
  def selenium_assert
    begin
      assert_not_equal "Action Controller: Exception caught", @selenium.get_title #usefull hack:)
      yield if Kernel.block_given?
    rescue Test::Unit::AssertionFailedError
      @verification_errors << $!
    end
  end

  
  # Code for manipulating actual time in tests (from http://www.ruby-forum.com/topic/114087#267920)
  def with_dates(*dates, &block)
    dates.flatten.each do |date|
      begin
        Time.forced_now = case date
        when String then DateTime.parse(date)
        when Time then DateTime.parse(date.to_s)
        else
          date
        end
        Date.forced_today = Date.new(Time.now.year,
          Time.now.month,
          Time.now.day)
        yield
      rescue Exception => e
        raise e
      ensure
        Time.forced_now = nil
        Date.forced_today = nil
      end
    end
  end

  # end of Date maniputaion code


  def create_goal(save = true, user = @jarek)
    g = Goal.new

    g.category = user.income
    g.period_type = :SELECTED
    g.period_start = Date.today
    g.period_end = Date.today
    g.goal_type_and_currency = 'PLN'
    g.value = 2.2
    g.description = 'Testowy plan'
    g.user = user

    g.save! if save
    g
  end

  def assert_goals_equal(g1, g2)
    assert_equal g1.user, g2.user
    assert_equal g1.category, g2.category
    assert_equal g1.period_type, g2.period_type
    assert_equal g1.period_start, g2.period_start
    assert_equal g1.period_end, g2.period_end
    assert_equal g1.goal_type_and_currency, g2.goal_type_and_currency
    assert_equal g1.value, g2.value
    assert_equal g1.description, g2.description
    assert_equal g1.is_cyclic, g2.is_cyclic
    assert_equal g1.is_finished, g2.is_finished
    assert_equal g1.cycle_group, g2.cycle_group
  end


end
