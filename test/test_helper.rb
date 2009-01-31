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
    make_currencies
    @zloty.save! if @zloty.id.nil?
    @rupert = User.new()
    @rupert.active = true
    @rupert.email = 'email@example.com'
    @rupert.login = 'rupert_XYZ_ab'
    @rupert.password = @rupert.login
    @rupert.password_confirmation = @rupert.login
    @rupert.transaction_amount_limit_type = :actual_month
    @rupert.multi_currency_balance_calculating_algorithm = :show_all_currencies
    @rupert.default_currency = @zloty
    @rupert.save!
    @rupert.activate!
  end


  def save_jarek
    @jarek = User.new()
    @jarek.active = true
    @jarek.email = 'jarek@example.com'
    @jarek.login = 'jarek_XYZ_ab'
    @jarek.password = @jarek.login
    @jarek.password_confirmation = @jarek.login
    @jarek.transaction_amount_limit_type = :actual_month
    @jarek.save!
    @jarek.activate!
  end


  def make_currencies
    unless @currencies
      @zloty = Currency.new(:symbol => 'zl', :long_symbol => 'PLN', :name => 'Złoty', :long_name =>'Polski złoty')
      @dolar = Currency.new(:symbol => '$', :long_symbol => 'USD', :name => 'Dolar', :long_name =>'Dolar amerykańcki')
      @euro = Currency.new(:symbol => '€', :long_symbol => 'EUR', :name => 'Euro', :long_name =>'Europejckie euro')
      @currencies = [@zloty, @euro, @dolar]
    end
  end


  def save_currencies
    make_currencies
    @currencies.each {|currency| currency.save!}
  end


  def log_rupert
    #    @request.session[:user_id] = @rupert.id
    log_user(@rupert)
  end


  def log_user(user)
    @request.session[:user_id] = user.id
  end
  

  def add_category_options(user, report)
    user.categories.each do |c|
      report.category_report_options << CategoryReportOption.new({:category => c, :inclusion_type => :both})
    end
  end


  def make_simple_transfer(options = {})
    hash = {:day => 1.day.ago.to_date, :description =>'empty', :user => @rupert, :currency => @zloty, :value => 100, :income => @rupert.categories.first, :outcome => @rupert.categories.second }
    hash.merge! options

    transfer = Transfer.new(:user => hash[:user])
    transfer.day = hash[:day]
    transfer.description = hash[:description]

    transfer.transfer_items << TransferItem.new(
      :category => hash[:income],
      :currency => hash[:currency],
      :description => hash[:description],
      :value => hash[:value])

    transfer.transfer_items << TransferItem.new(
      :category => hash[:outcome],
      :currency => hash[:currency],
      :description => hash[:description],
      :value => -1*hash[:value])
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

  
  def assert_menu(menu_items, action)
    assert_select 'div#bottom-menu' do
      assert_select 'span#kind-of-transfer > span', menu_items.size
      assert_select 'span#kind-of-transfer' do
        menu_items.each do |type|
          assert_select "span#kind-of-transfer-#{type}" do
            ['active','inactive'].each do |type2|
              assert_select "span.kind-of-transfer-#{type2}-tab"
            end
          end
        end
      end
      assert_select 'div#form-for-transfer' do
        assert_select 'div#form-for-transfer-full'
        assert_select 'div#form-for-transfer-search' do
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
    unless `ps aux` =~ Regexp.new("memcached -d -p #{MEMCACHED_PORT}")
      `memcached -d -p #{MEMCACHED_PORT}`
    end
  end

  def create_share_report(user)
    r = ShareReport.new
    r.user = user
    r.category = user.categories.first
    r.report_view_type = :pie
    r.period_type = :week
    r.share_type = :percentage
    r.depth = 5
    r.max_categories_count = 6
    r.name = "Testowy raport"
    r.save!
    r
  end

  def create_flow_report(user)
    r = FlowReport.new
    r.user = user
    add_category_options user, r
    r.report_view_type = :text
    r.period_type = :week
    r.name = "Testowy raport"
    r.save!
    r
  end

  def create_value_report(user)
    r = ValueReport.new
    r.user = user
    add_category_options user, r
    r.report_view_type = :bar
    r.period_type = :custom
    r.period_start = 5.month.ago
    r.period_end = Date.today.to_date
    r.period_division = :week
    r.name = "Testowy raport"
    r.save!
    r
  end




  

end
