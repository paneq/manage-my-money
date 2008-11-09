require 'test_helper'

class CategoryTest < Test::Unit::TestCase
  #fixtures :categories

  def setup
    @user = User.new()
    @user.active = true
    @user.email = 'email@example.com'
    @user.name = 'rupert'
    @user.password = 'p@ssword'
    @user.password_confirmation = 'p@ssword'
    @user.save!
   
  end
  
  def test_user_has_required_categories_after_created
    assert_equal 5, @user.categories.count, "User should have 5 categories after creation"
  end
  
  def test_zero_saldo_at_start
    @user.categories.each do |category|
      assert category.saldo_new.is_empty?, "Category should have saldo = 0 at the begining"
      assert_equal 0, category.saldo_new.currencies.size, "At the beggining saldo does not contains any currency"
    end
  end
  
  def test_saldo_after_transfers_in_one_currency
    currency = Currency.new(:symbol => 'zl', :long_symbol => 'PLN', :name => 'Złoty', :long_name =>'Polski złoty')
    currency.save!
    
    income_category = @user.categories[0]
    outcome_category = @user.categories[1]
    
    transfer = Transfer.new(:user => @user)
    transfer.day = 1.day.ago
    transfer.description =''
    
    transfer.transfer_items << TransferItem.new(:category => income_category, :currency => currency, :gender => true, :description => '', :value => 100)
    transfer.transfer_items << TransferItem.new(:category => outcome_category, :currency => currency, :gender => false, :description => '', :value => -100)
    transfer.save!
    
    assert_equal(100, income_category.saldo_new.value(currency), "Saldo should change of the same value as transfer item for given category")
    assert_equal(-100, outcome_category.saldo_new.value(currency), "Saldo should change of the same value as transfer item for given category")
    
    assert income_category.saldo_new.currencies.include?(currency)
    assert outcome_category.saldo_new.currencies.include?(currency)
    
    assert_equal 1, income_category.saldo_new.currencies.size
    assert_equal 1, outcome_category.saldo_new.currencies.size
    
    income_category = @user.categories[1]
    outcome_category = @user.categories[2]
    
    transfer = Transfer.new(:user => @user)
    transfer.day = 1.day.from_now
    transfer.description =''
    
    transfer.transfer_items << TransferItem.new(:category => income_category, :currency => currency, :gender => true, :description => '', :value => 200)
    transfer.transfer_items << TransferItem.new(:category => outcome_category, :currency => currency, :gender => false, :description => '', :value => -200)
    transfer.save!    
    
    assert_equal(-100 + 200, income_category.saldo_new.value(currency), "Saldo should change of the same value as transfer item for given category")
    assert_equal(-200, outcome_category.saldo_new.value(currency), "Saldo should change of the same value as transfer item for given category")
    
    assert_equal 1, income_category.saldo_new.currencies.size
    assert_equal 1, outcome_category.saldo_new.currencies.size
  end
  
  def test_saldo_after_transfers_in_many_currencies
    zloty = Currency.new(:symbol => 'zl', :long_symbol => 'PLN', :name => 'Złoty', :long_name =>'Polski złoty')
    euro = Currency.new(:symbol => 'E', :long_symbol => 'EUR', :name => 'Euro', :long_name =>'euro euro')
    zloty.save!
    euro.save!
    
    income_category = @user.categories[0]
    outcome_income_category = @user.categories[1]
    outcome_category = @user.categories[2]
    
    transfer = Transfer.new(:user => @user)
    transfer.day = 1.day.ago
    transfer.description =''
    
    transfer.transfer_items << TransferItem.new(:category => income_category, :currency => zloty, :gender => true, :description => '', :value => 100)
    transfer.transfer_items << TransferItem.new(:category => outcome_income_category, :currency => zloty, :gender => false, :description => '', :value => -100)
    transfer.save!
    
    transfer = Transfer.new(:user => @user)
    transfer.day = 1.day.from_now
    transfer.description =''
    
    transfer.transfer_items << TransferItem.new(:category => outcome_income_category, :currency => euro, :gender => true, :description => '', :value => 200)
    transfer.transfer_items << TransferItem.new(:category => outcome_category, :currency => euro, :gender => false, :description => '', :value => -200)
    transfer.save!    
    
    assert_equal(-100, outcome_income_category.saldo_new.value(zloty), "Saldo should change of the same value as transfer item for given category")
    assert_equal(200, outcome_income_category.saldo_new.value(euro), "Saldo should change of the same value as transfer item for given category")
    
    assert_equal 2, outcome_income_category.saldo_new.currencies.size
    assert outcome_income_category.saldo_new.currencies.include?(zloty)
    assert outcome_income_category.saldo_new.currencies.include?(euro)
  end
end
