require File.dirname(__FILE__) + '/../test_helper'

class TransferItemTest < Test::Unit::TestCase

  def setup
    @ti = TransferItem.new
  end


  def test_type_set
    assert_nothing_raised do
      [:income, :INComE, 'income', 'INCome', :outcome, :outCOME, 'outcome', 'oUtComE'].each { |income_type| @ti.transfer_item_type= income_type }
    end
  end

  def test_type_when_not_set

    assert_raise RuntimeError do
      @ti.transfer_item_type
    end

    @ti.value = 300
    assert_equal :income, @ti.transfer_item_type, "Transfer items with value > 0 should be of type: :income"

    @ti.value = 0
    assert_equal :income, @ti.transfer_item_type, "Transfer items with value == 0 should be of type: :income"

    @ti.value = -300
    assert_equal :outcome, @ti.transfer_item_type, "Transfer items with value < 0 should be of type: :outcome"
  end


  def test_type_when_set
    assert_raise RuntimeError do
      @ti.transfer_item_type = :bad_symbol
    end

    [:income, :outcome].each do |item_type|
      [300, 0, -300].each do |value|
        @ti.transfer_item_type = item_type
        @ti.value = value
        assert_equal item_type, @ti.transfer_item_type, "Transfer items should be of type: #{item_type} when set to #{item_type} and value was set to #{value}"
        @ti.valid? #assumes calls validation
      end
    end

  end


  def test_value_when_type_not_set
    [300.0, 0, -300.2].each do |value|
      @ti.value = value
      @ti.valid? #assumes calls validation
      assert_equal value, @ti.value
    end
  end


  def test_value_when_type_was_set
    @ti.value = 300
    @ti.transfer_item_type=(:income)
    @ti.valid? #assumes calls validation
    assert_equal 300, @ti.value
    assert_equal :income, @ti.transfer_item_type


    @ti.value = 300
    @ti.transfer_item_type=(:outcome)
    @ti.valid? #assumes calls validation
    assert_equal(-300, @ti.value)
    assert_equal :outcome, @ti.transfer_item_type

    @ti.value = -300
    @ti.transfer_item_type=(:income)
    @ti.valid? #assumes calls validation
    assert_equal(-300, @ti.value)
    assert_equal :outcome, @ti.transfer_item_type

    @ti.value = -300
    @ti.transfer_item_type=(:outcome)
    @ti.valid? #assumes calls validation
    assert_equal 300, @ti.value
    assert_equal :income, @ti.transfer_item_type
  end

end
