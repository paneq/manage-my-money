require File.dirname(__FILE__) + '/../test_helper'

class TransferTest < Test::Unit::TestCase

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
    assert_equal @rupert.categories.top_of_type(:EXPENSE), one.category
    assert_equal @rupert.default_currency, one.currency

    two = @transfer.transfer_items.find_by_description 'two'
    assert_equal(-100, two.value)
    assert_equal @rupert.categories.top_of_type(:INCOME), two.category
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
          'category' => @rupert.categories.top_of_type(:ASSET),
          'value' => '200',
          :transfer_item_type => 'income'
        },
        two.id.to_s => {
          'description' => 'new',
          'category' => @rupert.categories.top_of_type(:LOAN),
          'value' => '-200'
        }
      }
    end

    one = @transfer.transfer_items(true).first
    two = @transfer.transfer_items(true).second

    assert_equal('new', one.description)
    assert_equal 200, one.value
    assert_equal @rupert.categories.top_of_type(:ASSET), one.category
    assert_equal @rupert.default_currency, one.currency

    assert_equal('new', two.description)
    assert_equal(-200, two.value)
    assert_equal @rupert.categories.top_of_type(:LOAN), two.category
    assert_equal @rupert.default_currency, two.currency
  end


  private

  def save_transfer
    @transfer = Transfer.new :day => Date.today, :user => @rupert, :description => 'test',
      :new_transfer_items_attributes => {
      'one' => {
        :description => 'one',
        :value => '100',
        :category => @rupert.categories.top_of_type(:EXPENSE),
        :currency => @rupert.default_currency
      },
      'two' => {
        :description => 'two',
        :value => '100',
        :transfer_item_type => 'outcome',
        :category => @rupert.categories.top_of_type(:INCOME),
        :currency => @rupert.default_currency
      }
    }

    assert_nothing_raised do
      @transfer.save!
    end

  end


end
