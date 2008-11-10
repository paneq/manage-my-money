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
   
    @zloty = Currency.new(:symbol => 'zl', :long_symbol => 'PLN', :name => 'Złoty', :long_name =>'Polski złoty')
    @euro = Currency.new(:symbol => 'E', :long_symbol => 'EUR', :name => 'Euro', :long_name =>'euro euro')
    @zloty.save!
    @euro.save!
    
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
    income_category = @user.categories[0]
    outcome_category = @user.categories[1]
    
    save_simple_transfer_item(:income_category => income_category, :outcome_category => outcome_category, :day => 1.day.ago, :currency => @zloty, :value => 100)
    
    assert_equal(100, income_category.saldo_new.value(@zloty), "Saldo should change of the same value as transfer item for given category")
    assert_equal(-100, outcome_category.saldo_new.value(@zloty), "Saldo should change of the same value as transfer item for given category")
    
    assert income_category.saldo_new.currencies.include?(@zloty)
    assert outcome_category.saldo_new.currencies.include?(@zloty)
    
    assert_equal 1, income_category.saldo_new.currencies.size
    assert_equal 1, outcome_category.saldo_new.currencies.size
    
    income_category = @user.categories[1]
    outcome_category = @user.categories[2]
    
    save_simple_transfer_item(:income_category => income_category, :outcome_category => outcome_category, :day => 1.day.from_now, :currency => @zloty, :value => 200)   
    
    assert_equal(-100 + 200, income_category.saldo_new.value(@zloty), "Saldo should change of the same value as transfer item for given category")
    assert_equal(-200, outcome_category.saldo_new.value(@zloty), "Saldo should change of the same value as transfer item for given category")
    
    assert_equal 1, income_category.saldo_new.currencies.size
    assert_equal 1, outcome_category.saldo_new.currencies.size
  end
  
  def test_saldo_after_transfers_in_many_currencies    
    income_category = @user.categories[0]
    outcome_income_category = @user.categories[1]
    outcome_category = @user.categories[2]
    
    save_simple_transfer_item(:income_category => income_category, :outcome_category => outcome_income_category, :day => 1.day.ago, :currency => @zloty, :value => 100)
    save_simple_transfer_item(:income_category => outcome_income_category, :outcome_category => outcome_category, :day => 1.day.from_now, :currency => @euro, :value => 200) 
    
    assert_equal(-100, outcome_income_category.saldo_new.value(@zloty), "Saldo should change of the same value as transfer item for given category")
    assert_equal(200, outcome_income_category.saldo_new.value(@euro), "Saldo should change of the same value as transfer item for given category")
    
    assert_equal 2, outcome_income_category.saldo_new.currencies.size
    assert outcome_income_category.saldo_new.currencies.include?(@zloty)
    assert outcome_income_category.saldo_new.currencies.include?(@euro)
  end
  
  
  def test_saldo_at_end_of_days
    income_category = @user.categories[0]
    outcome_category = @user.categories[1]
    
    total = 0;
    5.downto(1) do |number|
      value = number*10
      total +=value
      save_simple_transfer_item(:income_category => income_category, :outcome_category => outcome_category, :day => number.days.ago.to_date, :currency => @zloty, :value => value)
      assert_equal total, income_category.saldo_at_end_of_day(number.days.ago.to_date).value(@zloty)
      
      #day later
      save_simple_transfer_item(:income_category => income_category, :outcome_category => outcome_category, :day => (number-1).days.ago.to_date, :currency => @euro, :value => value)
      assert_equal total, income_category.saldo_at_end_of_day((number-1).days.ago.to_date).value(@euro)
    end
    
    assert income_category.saldo_at_end_of_day(6.days.ago.to_date).is_empty?, "Saldo should not contain anything if nothing happend in category before that day"
    assert_equal 1, income_category.saldo_at_end_of_day(5.days.ago.to_date).currencies.size, "Only one currency should be returned if transfers in only one currency occured"
    
    4.downto(0) do |number|
      assert_equal 2, income_category.saldo_at_end_of_day(number.days.ago.to_date).currencies.size, "Every currency that was used in category transfers should occure"
    end
    
  end


  def test_saldo_for_periods
    income_category = @user.categories[3]
    outcome_category = @user.categories[4]
    value = 100;

    4.downto(0) do |number|
      save_simple_transfer_item(:income_category => income_category, :outcome_category => outcome_category, :day => number.days.ago.to_date, :currency => @zloty, :value => value)
    end

    4.downto(0) do |number|
      start_day = number.days.ago.to_date;
      end_day = Date.today
      
      assert_equal value*(number+1), income_category.saldo_for_period_new(start_day, end_day).value(@zloty)
      assert_equal 1, income_category.saldo_for_period_new(start_day, end_day).currencies.size

      assert_equal 100, income_category.saldo_for_period_new(start_day, start_day).value(@zloty)
      assert_equal 1, income_category.saldo_for_period_new(start_day, start_day).currencies.size
    end

    assert income_category.saldo_for_period_new(100.days.ago, 5.days.ago).is_empty?
    assert income_category.saldo_for_period_new(1.days.from_now, 100.days.from_now).is_empty?

  end


  private


  def save_simple_transfer_item(hash_with_options)
    hash = hash_with_options.clone()
    fill_simple_transfer_item_option_hash_with_defaults(hash)
    
    transfer = Transfer.new(:user => hash[:user])
    transfer.day = hash[:day]
    transfer.description = hash[:description]
    
    transfer.transfer_items << TransferItem.new(
      :category => hash[:income_category], 
      :currency => hash[:currency],  
      :description => hash[:description], 
      :value => hash[:value])
    
    transfer.transfer_items << TransferItem.new(
      :category => hash[:outcome_category], 
      :currency => hash[:currency],
      :description => hash[:description], 
      :value => -1*hash[:value])
    
    transfer.save!
  end

  
  def fill_simple_transfer_item_option_hash_with_defaults(hash_with_options)
    hash_with_options[:day] ||= 1.day.ago
    hash_with_options[:description] ||= ''
    hash_with_options[:user] ||= @user
    hash_with_options[:currency] ||= @zloty
    hash_with_options[:value] ||= 100
  end
  
  
end
