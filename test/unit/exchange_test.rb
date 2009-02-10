require File.dirname(__FILE__) + '/../test_helper'

class ExchangeTest < Test::Unit::TestCase

  def setup
    save_currencies
    save_rupert
  end


  def test_validation
    e1 = Exchange.new(:left_to_right => 1.2, :right_to_left => 0.12, :left_currency => @euro, :right_currency => @zloty, :day => Date.today, :user => @rupert)
    assert e1.save
    e2 = Exchange.new(:left_to_right => 1.2, :right_to_left => 0.12, :left_currency => @zloty, :right_currency => @euro, :day => Date.today, :user => @rupert)
    assert e2.save
      
    assert e1.left_currency.id < e1.right_currency.id
    assert e2.left_currency.id < e2.right_currency.id
    

    e = Exchange.new()
    assert !e.valid?
    [:left_to_right, :right_to_left, :left_currency, :right_currency, :day].each do |field|
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

    Exchange.send(:define_method, :before_validation) do
    end

    tbl = [@zloty, @euro]
    tbl.sort! {|a,b| a.id <=> b.id}
    e = Exchange.new(:left_to_right => 1.2, :right_to_left => 0.12, :left_currency => tbl.second, :right_currency => tbl.first, :day => Date.today, :user => @rupert)

    assert !e.valid?
    assert_not_nil e.errors.on(:base)
    
  end

end
