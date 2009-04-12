require 'test_helper'

class ExchangeTest < ActiveSupport::TestCase

  def setup
    prepare_currencies
    save_rupert
  end


  def test_validation
    e1 = Exchange.new(:left_to_right => 1.2, :right_to_left => 0.12, :left_currency => @euro, :right_currency => @zloty, :day => Date.today, :user => @rupert)
    assert e1.save
    e2 = Exchange.new(:left_to_right => 1.2, :right_to_left => 0.12, :left_currency => @zloty, :right_currency => @euro, :day => Date.yesterday, :user => @rupert)
    assert e2.save
    e3 = Exchange.new(:left_to_right => 1.2, :right_to_left => 0.12, :left_currency => @zloty, :right_currency => @euro, :day => Date.today, :user => @rupert)
    assert !e3.save #already one with the same day, user, and currencies

    assert e1.left_currency.id < e1.right_currency.id
    assert e2.left_currency.id < e2.right_currency.id
    

    e = Exchange.new()
    assert !e.valid?
    [:left_to_right, :right_to_left, :left_currency, :right_currency].each do |field|
      assert_not_nil e.errors.on(field)
    end

    e = Exchange.new(:left_to_right => 1.2, :right_to_left => 0.8)
    assert !e.valid?
    assert_nil e.errors.on(:left_to_right)
    assert_nil e.errors.on(:right_to_left)

    e = Exchange.new(:left_to_right => -1.2, :right_to_left => 0.0)
    assert !e.valid?
    assert_not_nil e.errors.on(:left_to_right)
    assert_not_nil e.errors.on(:right_to_left)


    e = Exchange.new(:left_currency => @zloty, :right_currency => @zloty)
    assert !e.valid?
    assert_nil e.errors.on(:left_currency)
    assert_not_nil e.errors.on(:right_currency)


    e = Exchange.new(:day => nil)
    e.valid?
    assert_nil e.errors.on(:day)


    e = Exchange.new(:day => nil)
    e.day_required = true
    assert !e.valid?
    assert_not_nil e.errors.on(:day)
    
    #TODO napisać tak aby nie psuło innych testów - przedefiniuj tylko dla obiektu e
    #    Exchange.send(:define_method, :before_validation) do
    #    end
    #
    #    tbl = [@zloty, @euro]
    #    tbl.sort! {|a,b| a.id <=> b.id}
    #    e = Exchange.new(:left_to_right => 1.2, :right_to_left => 0.12, :left_currency => tbl.second, :right_currency => tbl.first, :day => Date.today, :user => @rupert)
    #
    #    assert !e.valid?
    #    assert_not_nil e.errors.on(:base)


    
  end

  def test_can_create_exchange_for_system_currency
    e = Exchange.new(:user => @rupert, :left_currency => @euro, :right_currency => @zloty)
    e.valid?
    assert_nil e.errors.on(:user_id)
  end

  
  # security
  def test_cannot_create_exchange_for_someone_currency
    save_jarek
    c1 = Currency.create!(:user => @jarek, :all => 'XYZ')
    c2 = Currency.create!(:user => @jarek, :all => 'ZYX')
    e = Exchange.new(:user => @rupert, :left_currency => c1, :right_currency => c2)
    assert !e.valid?
    assert !e.errors.on(:user_id).empty?
  end

  
  def test_user_id_protected
    e = Exchange.new(:user_id => @rupert.id)
    assert_nil e.user
  end

end
