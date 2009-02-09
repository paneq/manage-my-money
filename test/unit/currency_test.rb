require File.dirname(__FILE__) + '/../test_helper'

class CurrencyTest < Test::Unit::TestCase

  def setup
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


  def test_validation_long_symbol
    c = make_currency(:long_symbol => 'x')
    c.valid? #assumes call validation
    assert_not_nil c.errors.on(:long_symbol)

    c = make_currency(:long_symbol => 'ABCD')
    c.valid? #assumes call validation
    assert_not_nil c.errors.on(:long_symbol)

    c = make_currency(:long_symbol => 'XyZ')
    c.valid? #assumes call validation
    assert_not_nil c.errors.on(:long_symbol)
  end
end
