require 'test_helper'

class TransferTest < ActiveSupport::TestCase

  def setup
    save_rupert
  end


  def test_create_with_new_items
    save_transfer

    assert_equal @rupert, @transfer.user
    assert_equal 'test', @transfer.description
    assert_equal 2, @transfer.transfer_items.count

    one = @transfer.transfer_items.find_by_description 'one'
    assert_equal 100, one.value
    assert_equal @rupert.expense, one.category
    assert_equal @rupert.default_currency, one.currency

    two = @transfer.transfer_items.find_by_description 'two'
    assert_equal(-100, two.value)
    assert_equal @rupert.income, two.category
    assert_equal @rupert.default_currency, two.currency
    
  end


  def test_update_with_items
    save_transfer
    @transfer = Transfer.find_by_id(@transfer.id)
    assert_not_nil @transfer
    one = @transfer.transfer_items.first
    two = @transfer.transfer_items.second
    @transfer.attributes = {
      :day => Date.today,
      :description => 'new_description',
      :transfer_items_attributes => [{
          :currency_id => @rupert.default_currency.id,
          :description => 'new',
          :category => @rupert.asset,
          :value => '200',
          :transfer_item_type => 'income',
          :_delete => '0',
          :id => one.id
        },{
          :currency_id => @rupert.default_currency.id,
          :description => 'new',
          :category => @rupert.loan,
          :value => '-200',
          :_delete => '0',
          :id => two.id
        }]
    }
    assert @transfer.save

    @transfer = Transfer.find_by_id(@transfer.id)
    assert @transfer.save
    assert_equal 2, @transfer.transfer_items.count()
    one = @transfer.transfer_items(true).find_by_id(one.id)
    two = @transfer.transfer_items(true).find_by_id(two.id)

    assert_equal('new', one.description)
    assert_equal 200, one.value
    assert_equal @rupert.asset, one.category
    assert_equal @rupert.default_currency, one.currency

    assert_equal('new', two.description)
    assert_equal(-200, two.value)
    assert_equal @rupert.loan, two.category
    assert_equal @rupert.default_currency, two.currency
  end


  def test_validation_one_currency
    transfer = make_simple_transfer #creates good transfer
    transfer.transfer_items[0].value += 10 #makes it bad
    assert !transfer.valid?, "Transfer with two different sum of income and outcome elements should not be valid"
    assert_match( /Wartość.*różna/, transfer.errors.on('base'))

    transfer.transfer_items = [transfer.transfer_items.first]
    assert !transfer.valid?, "Transfer should have at least 2 elements to be valid"
    assert_match( /dwóch.*elementów/, transfer.errors.on('base').join(" "))
  end

  
  def test_validation_not_numerical_values
    transfer = make_simple_transfer
    transfer.transfer_items[0].value = "aba"
    transfer.transfer_items[1].value = 0
    transfer.transfer_items.build(:value => nil, :currency => @rupert.default_currency )
    assert_nothing_raised { !transfer.valid? }
    assert !transfer.valid?
  end


  def test_multicurrency_validation_without_errors
    transfer = make_simple_transfer
    transfer.transfer_items[0].value = -100
    transfer.transfer_items[0].currency = @euro
    transfer.transfer_items[1].value = 400
    transfer.transfer_items[1].currency = @rupert.default_currency
    transfer.conversions.build(:exchange => Exchange.new(
        :left_currency => @euro,
        :right_currency => @rupert.default_currency,
        :left_to_right => 4,
        :right_to_left => 1,
        :user => @rupert
      ))
    assert transfer.valid?
  end


  def test_multicurrency_validation_with_errors
    transfer = make_simple_transfer
    transfer.transfer_items[0].value = 100
    transfer.transfer_items[0].currency = @euro
    transfer.transfer_items[1].value = 400 #based on exchange it should be 200 -> error
    transfer.transfer_items[1].currency = @rupert.default_currency
    transfer.conversions.build(:exchange => Exchange.new(
        :left_currency => @euro,
        :right_currency => @rupert.default_currency,
        :left_to_right => 2,
        :right_to_left => 1,
        :user => @rupert
      ))
    assert !transfer.valid?
    assert transfer.errors.on(:base)
  end


  def test_destroying_with_dependencies
    klasses = [Transfer, TransferItem, Conversion, Exchange]
    counts = Hash.new
    klasses.each do |klass|
      counts[klass] = klass.count
    end
    transfer = make_simple_transfer
    transfer.transfer_items[0].currency = @euro
    transfer.transfer_items[1].currency = @rupert.default_currency
    transfer.conversions.build(:exchange => Exchange.new(
        :left_currency => @euro,
        :right_currency => @rupert.default_currency,
        :left_to_right => 1,
        :right_to_left => 1,
        :user => @rupert
      ))
    assert transfer.save

    klasses.each do |klass|
      assert counts[klass] < klass.count
    end

    transfer.destroy

    klasses.each do |klass|
      assert_equal counts[klass], klass.count
    end
  end


  #security:

  def test_errors_when_invalid_objects_owners
    save_jarek
    t = Transfer.new(:user => @rupert)
    t.transfer_items.build(:category => @jarek.asset)
    assert !t.valid?
    assert t.errors.on(:user_id)

    t = Transfer.new(:user => @rupert)
    t.conversions.build(:exchange => Exchange.new(:user => @jarek))
    assert !t.valid?
    assert t.errors.on(:user_id)

    cur = @jarek.currencies.create!(:all => 'NEW')

    t = Transfer.new(:user => @rupert)
    t.transfer_items.build(:currency => cur)
    assert !t.valid?
    assert t.errors.on(:user_id)

    t = Transfer.new(:user => @rupert)
    t.conversions.build(:exchange => Exchange.new(:user => @rupert, :left_currency => cur))
    assert !t.valid?
    assert t.errors.on(:user_id)

    t = Transfer.new(:user => @rupert)
    t.conversions.build(:exchange => Exchange.new(:user => @rupert, :right_currency => cur))
    assert !t.valid?
    assert t.errors.on(:user_id)
  end


  private


  def save_transfer
    @transfer = Transfer.new :day => Date.today, :user => @rupert, :description => 'test',
      :transfer_items_attributes => {
      '0' => {
        :description => 'one',
        :value => '100',
        :category => @rupert.expense,
        :currency => @rupert.default_currency
      },
      '1' => {
        :description => 'two',
        :value => '100',
        :transfer_item_type => 'outcome',
        :category => @rupert.income,
        :currency => @rupert.default_currency
      }
    }

    assert_nothing_raised do
      @transfer.save!
    end

  end


end
