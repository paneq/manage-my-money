require 'test_helper'

class TransferItemTest < ActiveSupport::TestCase

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


  def test_validate_when_no_value_was_set
    @ti.transfer_item_type=(:outcome)
    assert_nothing_raised { @ti.valid? }
  end


  def test_validation_value
    @ti.value = nil
    @ti.valid?
    assert_equal 2, @ti.errors.on(:value).size
    errors = @ti.errors.on(:value).join(' ')
    assert_match(/nie jest prawidłową liczbą/, errors)
    assert_match(/pusta/, errors)

    @ti = TransferItem.new
    @ti.transfer_item_type=(:outcome)
    @ti.value = "ABSURD"
    @ti.valid?
    assert_not_nil @ti.errors.on(:value)
    assert_match( /nie jest prawidłową liczbą/, @ti.errors.on(:value))

    @ti = TransferItem.new
    @ti.value = "ABSURD"
    @ti.transfer_item_type=(:income)
    @ti.valid?
    assert_not_nil @ti.errors.on(:value)
    assert_match( /nie jest prawidłową liczbą/, @ti.errors.on(:value))

    #TODO: To ma przechodzić !
    t = Transfer.new()
    ti = t.transfer_items.build(:value =>"ABSURD", :transfer_item_type => :income)
    assert !t.valid?
    assert !ti.errors.empty?
    assert_match( /nie jest prawidłową liczbą/, ti.errors.on(:value))
  end


  def test_validation_category_and_currency
    [:category, :currency].each do |relation|
      @ti.send(relation, nil)
      @ti.valid?
      assert_equal 1, [@ti.errors.on(relation)].flatten.size
      assert_match(/pusta/, @ti.errors.on(relation))
    end
  end

end
