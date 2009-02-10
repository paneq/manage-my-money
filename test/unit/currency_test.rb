require File.dirname(__FILE__) + '/../test_helper'

class CurrencyTest < Test::Unit::TestCase

  def setup
    save_rupert
    save_currencies
  end


  def test_save
    assert_nothing_raised do
      save_currency(:name => 'my name', :long_name =>'long name', :symbol => 'sl', :long_symbol => 'SML', :user => nil)
    end
    assert_not_nil Currency.find_by_name('my name')
  end


  def test_validation_on_empty_fields
    String.send(:define_method, :join) do
      self
    end
    [:name, :long_name, :symbol, :long_symbol].each do |field|
      [nil, ''].each do |value|
        c = make_currency({field => value})
        c.valid? #assumes call validation
        assert_match(/pust[y|a|o|e]/, c.errors.on(field).join(' '))
      end
    end
  end


  def test_validation_long_symbol_and_name
    save_jarek
    
    c = make_currency(:long_symbol => 'x')
    c.valid? #assumes call validation
    assert_not_nil c.errors.on(:long_symbol)


    c = make_currency(:long_symbol => 'ABCD')
    c.valid? #assumes call validation
    assert_not_nil c.errors.on(:long_symbol)

    c = make_currency(:long_symbol => 'XyZ')
    c.valid? #assumes call validation
    assert_not_nil c.errors.on(:long_symbol)

    assert_nothing_raised do
      #same long_symbols, different users
      save_currency(:user => @rupert)
      save_currency(:user => @jarek)
    end

    c = make_currency(:user => @rupert)
    c.valid?
    assert_not_nil c.errors.on(:long_symbol) #already in use
    assert_not_nil c.errors.on(:long_name) #already in use

    assert_nil Currency.find(:first, :conditions => ['user_id IS NULL AND long_symbol = ?', make_currency().long_symbol])
    assert_nothing_raised do
      save_currency(:user => nil) # used by users but not by the system
    end


    save_currency(:user => nil, :long_symbol => 'XYZ', :long_name => 'XYZ')
    c = make_currency(:user => @rupert, :long_symbol => 'XYZ', :long_name => 'XYZ')
    c.valid?
    assert_not_nil c.errors.on(:long_symbol) #already in use by the system
    assert_not_nil c.errors.on(:long_name) #already in use by the system
  end


  def test_currencies_for_user
    save_jarek
    assert_equal @currencies.size, Currency.for_user(@rupert).size
    assert_equal @currencies.size, Currency.for_user(@jarek).size

    save_currency(:user => @rupert)
    assert_equal @currencies.size + 1, Currency.for_user(@rupert).size
    assert_equal @currencies.size, Currency.for_user(@jarek).size
  end


  def test_currencies_for_user_in_period
    save_jarek
    assert_equal [], Currency.for_user_period(@rupert, Date.today, Date.today)
    assert_equal [], Currency.for_user_period(@jarek, Date.today, Date.today)

    save_simple_transfer(:user => @rupert, :day => Date.today, :currency => @zloty)
    assert_equal [@zloty], Currency.for_user_period(@rupert, Date.today, Date.today)
    assert_equal [], Currency.for_user_period(@jarek, Date.today, Date.today)

    assert_equal [@zloty], Currency.for_user_period(@rupert, Date.yesterday, Date.tomorrow)
    assert_equal [], Currency.for_user_period(@jarek, Date.yesterday, Date.tomorrow)

    assert_equal [], Currency.for_user_period(@rupert, Date.tomorrow, Date.tomorrow)
    assert_equal [], Currency.for_user_period(@jarek, Date.tomorrow, Date.tomorrow)
  end


  def test_currencies_used_by
    save_jarek

    assert_equal [], Currency.used_by(@rupert)
    assert_equal [], Currency.used_by(@jarek)

    transfers = []
    transfers << save_simple_transfer(:user => @rupert, :currency => @zloty)

    assert_equal [@zloty], Currency.used_by(@rupert)
    assert_equal [], Currency.used_by(@jarek)

    transfers << save_simple_transfer(:user => @rupert, :currency => @euro)
    
    assert Currency.used_by(@rupert).include?(@zloty)
    assert Currency.used_by(@rupert).include?(@euro)
    assert_equal [], Currency.used_by(@jarek)

    transfers << save_simple_transfer(:user => @jarek, :currency => @euro)

    assert Currency.used_by(@rupert).include?(@zloty)
    assert Currency.used_by(@rupert).include?(@euro)
    assert_equal [@euro], Currency.used_by(@jarek)

    transfers.each {|t| t.destroy}
    assert_equal [], Currency.used_by(@rupert)
    assert_equal [], Currency.used_by(@jarek)
  end


  def test_currencies_exchanged_by
    save_jarek
    rupert_currency = save_currency(:user => @rupert)
    jarek_currency = save_currency(:user => @jarek)

    assert_equal [], Currency.exchanged_by(@rupert)
    assert_equal [], Currency.exchanged_by(@jarek)

    Exchange.new(:left_currency =>@zloty, :right_currency => @euro, :left_to_right => 1.0, :right_to_left => 1.0, :user => @rupert, :day => Date.today).save!

    assert Currency.exchanged_by(@rupert).include?(@euro)
    assert Currency.exchanged_by(@rupert).include?(@zloty)
    assert_equal [], Currency.exchanged_by(@jarek)

    Exchange.new(:left_currency =>rupert_currency, :right_currency => @euro, :left_to_right => 1.0, :right_to_left => 1.0, :user => @rupert, :day => Date.tomorrow).save!
    
    assert Currency.exchanged_by(@rupert).include?(@euro)
    assert Currency.exchanged_by(@rupert).include?(@zloty)
    assert Currency.exchanged_by(@rupert).include?(rupert_currency)

    Exchange.new(:left_currency =>jarek_currency, :right_currency => @euro, :left_to_right => 1.0, :right_to_left => 1.0, :user => @rupert, :day => Date.yesterday).save!
    
    assert_equal [jarek_currency], Currency.exchanged_by(@jarek)
    assert Currency.exchanged_by(@rupert).include?(@euro)
    assert Currency.exchanged_by(@rupert).include?(@zloty)
    assert Currency.exchanged_by(@rupert).include?(rupert_currency)
  end


  def test_is_system
    assert @zloty.is_system?
    assert !save_currency().is_system?
  end


  def test_indestructible
    save_simple_transfer(:currency => @zloty)
    assert !@zloty.destroy # Cannot be destroyed when used be at least 1 transfer item
    assert_equal :has_transfer_items, @zloty.why_not_destroyed
  end


  def test_destructible
    assert @zloty.destroy
    assert_nil @zloty.why_not_destroyed
  end
end
