require 'test_helper'

class CategoryTest < Test::Unit::TestCase
  #fixtures :categories

  def setup
    save_currencies
    save_rupert
    save_jarek
  end
  
  
  def test_zero_saldo_at_start
    @rupert.categories.each do |category|
      assert category.saldo_new.is_empty?, "Category should have saldo = 0 at the begining"
      assert_equal 0, category.saldo_new.currencies.size, "At the beggining saldo does not contains any currency"
    end
  end
  
  def test_saldo_after_transfers_in_one_currency    
    income_category = @rupert.categories[0]
    outcome_category = @rupert.categories[1]
    
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 1.day.ago, :currency => @zloty, :value => 100)
    
    assert_equal(100, income_category.saldo_new.value(@zloty), "Saldo should change of the same value as transfer item for given category")
    assert_equal(-100, outcome_category.saldo_new.value(@zloty), "Saldo should change of the same value as transfer item for given category")
    
    assert income_category.saldo_new.currencies.include?(@zloty)
    assert outcome_category.saldo_new.currencies.include?(@zloty)
    
    assert_equal 1, income_category.saldo_new.currencies.size
    assert_equal 1, outcome_category.saldo_new.currencies.size
    
    income_category = @rupert.categories[1]
    outcome_category = @rupert.categories[2]
    
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 1.day.from_now, :currency => @zloty, :value => 200)
    
    assert_equal(-100 + 200, income_category.saldo_new.value(@zloty), "Saldo should change of the same value as transfer item for given category")
    assert_equal(-200, outcome_category.saldo_new.value(@zloty), "Saldo should change of the same value as transfer item for given category")
    
    assert_equal 1, income_category.saldo_new.currencies.size
    assert_equal 1, outcome_category.saldo_new.currencies.size
  end
  
  def test_saldo_after_transfers_in_many_currencies    
    income_category = @rupert.categories[0]
    outcome_income_category = @rupert.categories[1]
    outcome_category = @rupert.categories[2]
    
    save_simple_transfer(:income => income_category, :outcome => outcome_income_category, :day => 1.day.ago, :currency => @zloty, :value => 100)
    save_simple_transfer(:income => outcome_income_category, :outcome => outcome_category, :day => 1.day.from_now, :currency => @euro, :value => 200)
    
    assert_equal(-100, outcome_income_category.saldo_new.value(@zloty), "Saldo should change of the same value as transfer item for given category")
    assert_equal(200, outcome_income_category.saldo_new.value(@euro), "Saldo should change of the same value as transfer item for given category")
    
    assert_equal 2, outcome_income_category.saldo_new.currencies.size
    assert outcome_income_category.saldo_new.currencies.include?(@zloty)
    assert outcome_income_category.saldo_new.currencies.include?(@euro)
  end


  def test_inverting_income_saldo
    income_category = @rupert.income
    outcome_income_category = @rupert.asset

    save_simple_transfer(:income => income_category, :outcome => outcome_income_category, :day => 1.day.ago, :currency => @zloty, :value => 100)

    assert_equal(100, income_category.saldo_new.value(@zloty))
    @rupert.invert_saldo_for_income = true
    @rupert.save!
    income_category = @rupert.income
    assert_equal(-100, income_category.saldo_new.value(@zloty))
    @rupert.invert_saldo_for_income = false
    @rupert.save!
    income_category = @rupert.income
    assert_equal(100, income_category.saldo_new.value(@zloty))

  end


  
  
  def test_saldo_at_end_of_days
    income_category = @rupert.categories[0]
    outcome_category = @rupert.categories[1]
    
    total = 0;
    5.downto(1) do |number|
      value = number*10
      total +=value
      save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => number.days.ago.to_date, :currency => @zloty, :value => value)
      assert_equal total, income_category.saldo_at_end_of_day(number.days.ago.to_date).value(@zloty)
      
      #day later
      save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => (number-1).days.ago.to_date, :currency => @euro, :value => value)
      assert_equal total, income_category.saldo_at_end_of_day((number-1).days.ago.to_date).value(@euro)
    end
    
    assert income_category.saldo_at_end_of_day(6.days.ago.to_date).is_empty?, "Saldo should not contain anything if nothing happend in category before that day"
    assert_equal 1, income_category.saldo_at_end_of_day(5.days.ago.to_date).currencies.size, "Only one currency should be returned if transfers in only one currency occured"
    
    4.downto(0) do |number|
      assert_equal 2, income_category.saldo_at_end_of_day(number.days.ago.to_date).currencies.size, "Every currency that was used in category transfers should occure"
    end
    
  end


  def test_saldo_for_periods
    income_category = @rupert.categories[3]
    outcome_category = @rupert.categories[4]
    value = 100;

    4.downto(0) do |number|
      save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => number.days.ago.to_date, :currency => @zloty, :value => value)
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

  def test_saldo_after_day
    income_category = @rupert.categories[2]
    outcome_category = @rupert.categories[3]
    value = 100;

    4.downto(0) do |number|
      save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => number.days.ago.to_date, :currency => @zloty, :value => value)
    end

    5.downto(1) do |number|
      day = number.days.ago.to_date;

      assert_equal value*(number), income_category.saldo_after_day_new(day).value(@zloty)
      assert_equal 1, income_category.saldo_after_day_new(day).currencies.size
    end
    
    assert income_category.saldo_after_day_new(Date.today).is_empty?
  end


  def test_saldo_calculate_with_exchanges_closest_to_transaction
    @rupert.multi_currency_balance_calculating_algorithm = :calculate_with_exchanges_closest_to_transaction
    @rupert.save!
    income_category = @rupert.categories[0]
    outcome_category = @rupert.categories[1]
    value = 100
    first_exchange_rate = 4
    second_exchange_rate = first_exchange_rate / 2
    bad_exchange_rate = 100

    #this exchange should not be used by algorithm becuase it is too far from any transfer day
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => 1.0 / first_exchange_rate, :right_to_left => first_exchange_rate, :day => 20.days.ago.to_date)

    #no exchange to use becuase it is in default currency already
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 6.days.ago.to_date, :currency => @zloty, :value => value)
    
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => 1.0 / first_exchange_rate, :right_to_left => first_exchange_rate, :day => 5.days.ago.to_date)
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 4.days.ago.to_date, :currency => @euro, :value => value)

    #this exchange ratio should not be used by algorithm becuase it belongs to another person
    @jarek.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 5.days.ago.to_date)
    #this exchange should not be used by algorithm becuase it is about other currencies
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@dolar, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 5.days.ago.to_date)
    
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => 1.0 / second_exchange_rate , :right_to_left => second_exchange_rate , :day => 3.days.ago.to_date)
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 2.days.ago.to_date, :currency => @euro, :value => value)

    saldo = income_category.saldo_for_period_new(6.days.ago.to_date, 2.days.ago.to_date)

    assert_equal 1, saldo.currencies.size
    assert_equal value + first_exchange_rate*value + second_exchange_rate*value, saldo.value(@zloty)
  end


  def test_saldo_calculate_with_newest_exchanges
    @rupert.multi_currency_balance_calculating_algorithm = :calculate_with_newest_exchanges
    @rupert.save!
    income_category = @rupert.categories[0]
    outcome_category = @rupert.categories[1]
    value = 100
    first_exchange_rate = 4
    bad_exchange_rate = 100

    #this exchange should not be used by algorithm becuase it is the newest one
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 20.days.ago.to_date)

    #no exchange to use becuase it is in default currency already
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 6.days.ago.to_date, :currency => @zloty, :value => value)

    #this exchange ratio should not be used by the algorithm becuase it is not the newest one
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 5.days.ago.to_date)

    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 4.days.ago.to_date, :currency => @euro, :value => value)

    #this exchange should not be used by algorithm becuase it is about other currencies
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@dolar, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 1.days.ago.to_date)

    #this exchange ratio should not be used by algorithm becuase it belongs to another person
    @jarek.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 1.days.ago.to_date)

    #this one should be used be the algorithm, right currencies, the newest one and belongs to the right user
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => 1.0 / first_exchange_rate , :right_to_left => first_exchange_rate , :day => 1.days.ago.to_date)
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 1.days.ago.to_date, :currency => @euro, :value => value)
    
    saldo = income_category.saldo_for_period_new(20.days.ago.to_date, 1.days.ago.to_date)

    assert_equal 1, saldo.currencies.size
    assert_equal value + 2*first_exchange_rate*value, saldo.value(@zloty)
  end


  def test_transfers_with_saldo_for_period
    income = @rupert.categories[1]
    outcome = @rupert.categories[2]
    value = 100;

    zloty_bonus = 000
    euro_bonus = 00

    save_simple_transfer(:income => income, :outcome => outcome, :day => 10.day.ago.to_date, :currency => @zloty, :value => zloty_bonus)
    save_simple_transfer(:income => income, :outcome => outcome, :day => 10.day.ago.to_date, :currency => @euro, :value => euro_bonus)

    5.downto(1) do |number|
      t = Transfer.new(:user => @rupert)
      t.day = number.days.ago.to_date
      t.description = ''

      number.times do
        t.transfer_items << TransferItem.new(:category => income, :currency => @zloty, :description => '', :value => value)
        t.transfer_items << TransferItem.new(:category => income, :currency => @euro, :description => '', :value => value)
      end
      t.transfer_items << TransferItem.new(:category => outcome, :currency => @zloty, :description => '', :value => -1*value*number)
      t.transfer_items << TransferItem.new(:category => outcome, :currency => @euro, :description => '', :value => -1*value*number)

      t.save!
    end

    5.downto(1) do |number|
      result = income.transfers_with_saldo_for_period_new(5.days.ago.to_date, number.days.ago.to_date)
      assert_equal 6 - number, result.size
      saldo = Money.new()
      5.downto(number) do |item_number|
        item = result[5-item_number]

        #test money
        assert_equal item_number*value, item[:money].value(@zloty)
        assert_equal item_number*value, item[:money].value(@euro)
        assert_equal 2, item[:money].currencies.size

        saldo.add!(item[:money])

        #test saldo
        assert_equal saldo.value(@zloty) + zloty_bonus, item[:saldo].value(@zloty)
        assert_equal saldo.value(@euro) + euro_bonus, item[:saldo].value(@euro)
        assert_equal 2, item[:saldo].currencies.size
      end
    end

    assert income.transfers_with_saldo_for_period_new(6.days.ago, 6.days.ago).empty?
    assert income.transfers_with_saldo_for_period_new(1.day.from_now, 1.day.from_now).empty?

  end


  def test_save_with_parent_category_in_valid_set
    @parent = @rupert.categories.top_of_type(:ASSET)
    category = Category.new(
      :name => 'test',
      :description => 'test',
      :user => @rupert,
      :parent => @parent
    )
    @rupert.categories << category
    @rupert.save!
    assert @parent.descendants.include?(category)
    assert_equal category.parent, @parent
    assert_equal :ASSET, category.category_type
    assert @rupert.categories.include?(category)
  end

  
  def test_should_not_save_without_user
    @parent = @rupert.categories.top_of_type(:ASSET)
    category = Category.new(
      :name => 'test',
      :description => 'test',
      :category_type => :ASSET,
      :user => nil,
      :parent => @parent
    )
    assert_raise ActiveRecord::ActiveRecordError do
      category.save
    end
  end


  def test_save_with_balance
    category = save_category(:opening_balance => 123.4, :opening_balance_currency => @zloty)
    saldo = category.saldo_new(:default, false)
    assert_equal 123.4, saldo.value
    assert_equal @zloty, saldo.currency
  end


  def test_save_with_bad_data
    category = make_category(:opening_balance => 123.4)
    assert !category.valid?
    assert_match(/nie może być pusta/, category.errors.on(:opening_balance_currency) )

    category = make_category(:opening_balance => 'XYZ')
    assert !category.valid?
    assert_match(/nie jest prawidłową liczbą/, category.errors.on(:opening_balance) )

    category = make_category(:name => nil)
    assert !category.valid?
    assert_match(/nie może być pusta/, category.errors.on(:name) )
  end


  def test_moves_child_categories_when_destroyed
    #Asset -
    #      |-test
    #         |-child1
    #         |-child2
    parent = @rupert.categories.top_of_type(:ASSET)
    category = Category.new(
      :name => 'test',
      :description => 'test',
      :user => @rupert,
      :parent => parent
    )
    @rupert.categories << category
    @rupert.save!
    
    child1 = Category.new(
      :name => 'child1',
      :description => 'child1',
      :user => @rupert,
      :parent => category
    )

    child2 = Category.new(
      :name => 'child2',
      :description => 'child2',
      :user => @rupert,
      :parent => category
    )
    @rupert.categories << child1 << child2
    @rupert.save!

    #Asset -
    #      |-child1
    #      |-child2

    @rupert.categories(true).find_by_name('test').destroy
    parent = @rupert.categories(true).top_of_type(:ASSET)
    
    assert_equal 7, @rupert.categories.size #5 top categories and 2 children of asset category
    assert_equal 2, parent.children.count
    assert_equal parent.children[0], child1
    assert_equal parent.children[1], child2
  end


  def test_indestructible_top_categories
    @rupert.categories.each do |top_category|
      assert_throws(:indestructible) {top_category.destroy}
    end
  end


  def test_moves_transfer_items_when_destroyed
    parent = @rupert.categories.top_of_type(:ASSET)
    category = Category.new(
      :name => 'test',
      :description => 'test',
      :user => @rupert,
      :parent => parent
    )
    @rupert.categories << category
    @rupert.save!

    #TODO : napisac
    save_simple_transfer(:income => parent, :outcome => category, :day => Time.now.to_date, :currency => @zloty, :value => 100)
    category.destroy
    assert_equal 2, parent.transfer_items.count
    assert_equal 0, parent.saldo_new.value(@zloty)
  end



  #TODO
  def test_calculate_share_values
    
  end

  #TODO
  def test_calculate_values
    
  end



  #przykłady na jednej walucie i prostych transferach
  def test_calculate_flow_values
    

    prepare_sample_catagory_tree_for_jarek
    category1 = @jarek.categories.top_of_type(:INCOME)
    category2 = @jarek.categories.find_by_name "child1"

    save_simple_transfer(:income => category1, :outcome => category2, :day => 1.day.ago, :currency => @zloty, :value => 100)

    #prosty przykład - jeden przepływ jedna wartosć
    categories = [category1]
    flow_values = Category.calculate_flow_values(categories, 1.year.ago.to_date, 1.year.from_now.to_date)
    assert_equal 1, flow_values[:in].size
    assert_equal 0, flow_values[:out].size
    assert_equal 100, flow_values[:in].first[:value].value(@zloty)

    #przypadek w którym podajemy wszystkie kategorie ktorych dotycza transakcje
    categories = [category1, category2]
    flow_values = Category.calculate_flow_values(categories, 1.year.ago.to_date, 1.year.from_now.to_date)
    assert_equal 0, flow_values[:in].size
    assert_equal 0, flow_values[:out].size


    save_simple_transfer(:income => category1, :outcome => category2, :day => 1.day.ago, :currency => @zloty, :value => 44)

    categories = [category1]
    flow_values = Category.calculate_flow_values(categories, 1.year.ago.to_date, 1.year.from_now.to_date)
    assert_equal 1, flow_values[:in].size
    assert_equal 0, flow_values[:out].size
    assert_equal 144, flow_values[:in].first[:value].value(@zloty)


    categories = [category1, category2]
    flow_values = Category.calculate_flow_values(categories, 1.year.ago.to_date, 1.year.from_now.to_date)
    assert_equal 0, flow_values[:in].size
    assert_equal 0, flow_values[:out].size
    

    save_simple_transfer(:income => category2, :outcome => category1, :day => 1.day.ago, :currency => @zloty, :value => 33)

    categories = [category1]
    flow_values = Category.calculate_flow_values(categories, 1.year.ago.to_date, 1.year.from_now.to_date)
    assert_equal 1, flow_values[:in].size
    assert_equal 1, flow_values[:out].size
    assert_equal 144, flow_values[:in].first[:value].value(@zloty)
    assert_equal 33, flow_values[:out].first[:value].value(@zloty)


    category3 = @jarek.categories.find_by_name "child2"
    save_simple_transfer(:income => category1, :outcome => category3, :day => 1.day.ago, :currency => @zloty, :value => 66)
    categories = [category1]
    flow_values = Category.calculate_flow_values(categories, 1.year.ago.to_date, 1.year.from_now.to_date)
    assert_equal 2, flow_values[:in].size
    assert_equal 1, flow_values[:out].size
    assert_equal 144, flow_values[:in].find{|el| el[:category].name == "child1"}[:value].value(@zloty)
    assert_equal 66, flow_values[:in].find{|el| el[:category].name == "child2"}[:value].value(@zloty)
    assert_equal 33, flow_values[:out].first[:value].value(@zloty)



    categories = [category1, category2, category3]
    flow_values = Category.calculate_flow_values(categories, 1.year.ago.to_date, 1.year.from_now.to_date)
    assert_equal 0, flow_values[:in].size
    assert_equal 0, flow_values[:out].size
    

    categories = [category1, category3]
    flow_values = Category.calculate_flow_values(categories, 1.year.ago.to_date, 1.year.from_now.to_date)
    assert_equal 1, flow_values[:in].size
    assert_equal 1, flow_values[:out].size
    assert_equal 144, flow_values[:in].first[:value].value(@zloty)
    assert_equal 33, flow_values[:out].first[:value].value(@zloty)

  end



  def test_name_with_path
    prepare_sample_catagory_tree_for_jarek
    category1 = @jarek.categories.top_of_type(:INCOME)
    category2 = @jarek.categories.find_by_name 'child1'

    assert_equal 'Przychody', category1.name_with_path
    assert_equal 'Zasoby:test:child1', category2.name_with_path

    category1.name = 'Nazwa'
    category1.save!
    assert_equal 'Nazwa', category1.name_with_path
    category2.name = 'NowaNazwa'
    category2.save!
    assert_equal 'Zasoby:test:NowaNazwa', category2.name_with_path

  end

  private



  def make_category(options = {})
    category = Category.new({
      :name => 'test',
      :description => 'test',
      :user => @rupert,
      :parent => @rupert.asset}.
      merge(options)
    )
  end


  def save_category(options = {})
    c = make_category(options)
    c.save!
    return c
  end

  
end
