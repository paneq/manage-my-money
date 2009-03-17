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
    one = @transfer.transfer_items.first
    two = @transfer.transfer_items.second
    assert_nothing_raised do
      @transfer.update_attributes! :existing_transfer_items_attributes => {
        one.id.to_s => {
          'description' => 'new',
          'category' => @rupert.asset,
          'value' => '200',
          :transfer_item_type => 'income'
        },
        two.id.to_s => {
          'description' => 'new',
          'category' => @rupert.loan,
          'value' => '-200'
        }
      }
    end

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

  private


  def save_transfer
    @transfer = Transfer.new :day => Date.today, :user => @rupert, :description => 'test',
      :new_transfer_items_attributes => {
      'one' => {
        :description => 'one',
        :value => '100',
        :category => @rupert.expense,
        :currency => @rupert.default_currency
      },
      'two' => {
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
