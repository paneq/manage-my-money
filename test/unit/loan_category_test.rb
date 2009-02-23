require 'test_helper'

class Counter
  def initialize
    @number = 100
  end
  def get
    @number -= 1
    return @number + 1
  end
end

class LoanCategoryTest < Test::Unit::TestCase

  def setup
    save_rupert
  end


  def test_Creating_Loan_Categories
    l = LoanCategory.new(:name => 'test', :user => @rupert, :parent => @rupert.loan)
    assert_equal :LOAN, l.category_type
    assert_equal 'LoanCategory', l.type.to_s

    assert l.save

    assert_equal :LOAN, l.category_type
    assert_not_nil LoanCategory.find_by_id(l.id)
    assert_not_nil Category.find_by_id(l.id)
    assert_equal 'LoanCategory', l.type.to_s
  end


  def test_Failing_to_create_loan_subcategories
    (rupert.categories.top - [rupert.loan] ).each do |top_category|
      l = LoanCategory.new(:name => 'test', :user => @rupert, :parent => top_category)
      assert_not_saved_becuase_cannot_become_loan_category l

      l = Category.new(:name => 'test', :user => @rupert, :parent => top_category)
      l[:type] = 'LoanCategory'
      assert_not_saved_becuase_cannot_become_loan_category l
    end
  end


  def test_Changing_to_Loan_Category
    c = Category.new(:name => 'test', :user => @rupert, :parent => @rupert.loan)
    assert c.save
    assert_equal :LOAN, c.category_type
    assert_nil LoanCategory.find_by_id(c.id)

    c[:type] = LoanCategory.to_s
    assert c.save

    c = Category.find(c.id)
    assert_equal :LOAN, c.category_type
    assert_not_nil LoanCategory.find_by_id(c.id)
  end


  def test_Failing_to_change_to_loan_categories

    rupert.categories.top.each do |top_category|
      top_category[:type] = 'LoanCategory'
      assert_not_saved_becuase_cannot_become_loan_category top_category
    end

    (rupert.categories.top - [rupert.loan] ).each do |top_category|
      category = Category.new(:name => 'test', :user => @rupert, :parent => top_category)
      category[:type] = 'LoanCategory'
      assert_not_saved_becuase_cannot_become_loan_category category
    end
    
  end


  def test_recent_unbalanced
    loan = LoanCategory.new(:name => 'test', :user => @rupert, :parent => @rupert.loan)
    loan.save!
    counter = Counter.new
    value = 30
    transfers = []

    #create 25 transfers day by day. Transfers have 1-3 transfer items that come to loan category. Value of transfer is always 30.
    25.times do
      number = counter.get
      day = number.days.ago.to_date
      transfer = Transfer.new(:user => @rupert, :day => day, :description => 'test')
      items = number % 3 + 1
      item_value = value / items
      items.times do
        transfer.transfer_items.build(:category => loan, :value => item_value, :currency => @zloty, :description => 'loan', :transfer_item_type => :income)
      end
      transfer.transfer_items.build(:category => @rupert.asset, :value => value, :currency => @zloty, :description => 'asset', :transfer_item_type => :outcome)
      transfer.save!
      transfers << transfer
    end

    #recent_unbalanced should give back last 20 transfers
    assert_equal transfers[5..24], loan.recent_unbalanced.map{|info| info[:transfer]}

    #make saldo = 0
    save_simple_transfer(:income => @rupert.asset, :outcome => loan, :value => loan.current_saldo.value(@zloty), :day => counter.get.days.ago.to_date)
    assert loan.current_saldo.empty?

    #when saldo is 0 then no unbalanced transfers should be returned
    assert_equal [], loan.recent_unbalanced.map{|info| info[:transfer]}

    transfers = []
    3.times do
      transfers << save_simple_transfer(:income => @rupert.asset, :outcome => loan, :value => 100, :day => counter.get.days.ago.to_date)
      assert_equal transfers, loan.recent_unbalanced.map{|info| info[:transfer]}
    end

    3.times do
      transfers << save_simple_transfer(:outcome => @rupert.asset, :income => loan, :value => 10, :day => counter.get.days.ago.to_date)
      assert_equal transfers, loan.recent_unbalanced.map{|info| info[:transfer]}
    end
  end


  private


  def assert_not_saved_becuase_cannot_become_loan_category(category)
    assert !category.save
    assert category.errors.on(:base)
    assert_match(/Tylko nienajwyższa kategoria typu 'Zobowiązania' może reprezentować Dłużnika lub Wierzyciela/, category.errors.on(:base).to_s)
  end
end
