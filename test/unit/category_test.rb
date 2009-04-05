require 'test_helper'

class CategoryTest < ActiveSupport::TestCase

  def setup
    prepare_currencies
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


  def test_saldo_calculate_with_exchanges_closest_to_transaction
    @rupert.multi_currency_balance_calculating_algorithm = :calculate_with_exchanges_closest_to_transaction
    @rupert.save!
    @rupert = User.find(@rupert.id) #Otherwise category.user.multi_currency_balance_calculating_algorithm = :show_all_currencies, WHY?
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

    @rupert.exchanges(true)
    saldo = income_category.saldo_for_period_new(6.days.ago.to_date, 2.days.ago.to_date)

    assert_equal 1, saldo.currencies.size
    assert_equal value + first_exchange_rate*value + second_exchange_rate*value, saldo.value(@zloty)
  end


  def test_saldo_calculate_with_newest_exchanges
    @rupert.multi_currency_balance_calculating_algorithm = :calculate_with_newest_exchanges
    @rupert.save!
    @rupert = User.find(@rupert.id) #Otherwise category.user.multi_currency_balance_calculating_algorithm = :show_all_currencies, WHY?
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
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@dolar, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 2.days.ago.to_date)

    #this exchange ratio should not be used by algorithm becuase it belongs to another person
    @jarek.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 2.days.ago.to_date)

    #this one should be used be the algorithm, right currencies, the newest one and belongs to the right user
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => 1.0 / first_exchange_rate , :right_to_left => first_exchange_rate , :day => 1.days.ago.to_date)
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 1.days.ago.to_date, :currency => @euro, :value => value)
    
    saldo = income_category.saldo_for_period_new(20.days.ago.to_date, 1.days.ago.to_date)

    assert_equal 1, saldo.currencies.size
    assert_equal value + 2*first_exchange_rate*value, saldo.value(@zloty)
  end


  def test_saldo_calculate_with_newest_exchanges_but
    @rupert.multi_currency_balance_calculating_algorithm = :calculate_with_newest_exchanges_but
    @rupert.save!
    @rupert = User.find(@rupert.id) #Otherwise category.user.multi_currency_balance_calculating_algorithm = :show_all_currencies, WHY?
    income_category = @rupert.categories[0]
    outcome_category = @rupert.categories[1]

    value = 100
    first_exchange_rate = 4
    second_exchange_rate = 8
    bad_exchange_rate = 100

    #this exchange should not be used by algorithm becuase it is not the newest one
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 20.days.ago.to_date)

    #no exchange to use becuase it is in default currency already
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 6.days.ago.to_date, :currency => @zloty, :value => value)

    #this exchange ratio should not be used by the algorithm becuase it is not the newest one
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 5.days.ago.to_date)

    #no conversions
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 4.days.ago.to_date, :currency => @euro, :value => value)

    #with conversions. Should use exchange connected to conversion insted of other one.
    t2 = save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 4.days.ago.to_date, :currency => @euro, :value => value)
    t2.conversions.create!(:exchange => Exchange.new(:user => @rupert, :left_currency => @zloty, :right_currency => @euro, :left_to_right => 1.0 / second_exchange_rate, :right_to_left => second_exchange_rate))
    t2.save!
  
    #this exchange should not be used by algorithm becuase it is about other currencies
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@dolar, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 2.days.ago.to_date)

    #this exchange ratio should not be used by algorithm becuase it belongs to another person
    @jarek.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => bad_exchange_rate, :right_to_left => bad_exchange_rate, :day => 2.days.ago.to_date)

    #this one should be used be the algorithm, right currencies, the newest one and belongs to the right user
    @rupert.exchanges.create!(:left_currency => @zloty, :right_currency =>@euro, :left_to_right => 1.0 / first_exchange_rate , :right_to_left => first_exchange_rate , :day => 1.days.ago.to_date)
    save_simple_transfer(:income => income_category, :outcome => outcome_category, :day => 1.days.ago.to_date, :currency => @euro, :value => value)

    saldo = income_category.saldo_for_period_new(20.days.ago.to_date, 1.days.ago.to_date)

    assert_equal 1, saldo.currencies.size
    assert_equal value + 2*first_exchange_rate*value + second_exchange_rate*value, saldo.value(@zloty)
  end


  def test_saldo_calculate_with_exchanges_closest_to_transaction_but
    @rupert.multi_currency_balance_calculating_algorithm = :calculate_with_exchanges_closest_to_transaction_but
    @rupert.save!
    @rupert = User.find(@rupert.id) #Otherwise category.user.multi_currency_balance_calculating_algorithm = :show_all_currencies, WHY?
    income_category = @rupert.categories[0]
    outcome_category = @rupert.categories[1]
    
    saldo = income_category.saldo_for_period_new(20.days.ago.to_date, 1.days.ago.to_date)
    #TODO: Write it
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
      
      t.conversions.build(:exchange => Exchange.new(:left_currency => @zloty, :right_currency => @euro, :left_to_right => 0.25, :right_to_left => 4))

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

    assert income.transfers_with_saldo_for_period_new(6.days.ago.to_date, 6.days.ago.to_date).empty?
    assert income.transfers_with_saldo_for_period_new(1.day.from_now.to_date, 1.day.from_now.to_date).empty?

  end


  def test_save_with_parent_category_in_valid_set
    @parent = @rupert.categories.top.of_type(:ASSET).first
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
    @parent = @rupert.categories.top.of_type(:ASSET).first
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
    parent = @rupert.categories.top.of_type(:ASSET).first
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
    parent = @rupert.asset
    
    assert_equal 7, @rupert.categories(true).size #5 top categories and 2 children of asset category
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
    parent = @rupert.asset
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
  def test_calculate_max_share_values
    prepare_sample_catagory_tree_for_jarek
    category1 = @jarek.asset
    category2 = @jarek.loan
    test_category = @jarek.categories.find_by_name 'test'

    assert_equal({}, category1.calculate_max_share_values(5, 3, 1.year.ago.to_date, 1.year.from_now.to_date))

    save_simple_transfer(:income => category1, :outcome => category2, :day => 1.day.ago, :currency => @zloty, :value => 100, :user => @jarek)

    result = category1.calculate_max_share_values(5, 3, 1.year.ago.to_date, 1.year.from_now.to_date)

    assert_equal 1, result.keys.size
    assert_not_nil result[@zloty]
    assert_equal 1, result[@zloty].size
    assert_equal true, result[@zloty].first[:without_subcategories]
    assert_equal 100, result[@zloty].first[:value].value(@zloty)
    assert_equal category1, result[@zloty].first[:category]

    save_simple_transfer(:income => test_category, :outcome => category2, :day => 1.day.ago, :currency => @zloty, :value => 50, :user => @jarek)

    result = category1.calculate_max_share_values(5, 3, 1.year.ago.to_date, 1.year.from_now.to_date)

    assert_equal 1, result.keys.size
    assert_not_nil result[@zloty]
    assert_equal 2, result[@zloty].size
    assert_equal true, result[@zloty].first[:without_subcategories]
    assert_equal 100, result[@zloty].first[:value].value(@zloty)
    assert_equal category1, result[@zloty].first[:category]

    assert_equal true, result[@zloty][1][:without_subcategories]
    assert_equal 50, result[@zloty][1][:value].value(@zloty)
    assert_equal test_category, result[@zloty][1][:category]



    
    #TODO
    # przetestować czy zwraca dobre wyniki
    # na 1 poziomie zagłebienia
    # na różnym od pierwszego poziomie
    # sprawdzić czy zwraca dobrą liczbę wyników i czy 'pozostałe' są dobrze policzone
    #sprawdzić czy działa jeśli w podkategoriach saldo jest zerowe lub nie ma transferów
    # sprawdzić działanie dla wielu walut


  end

  #TODO
  def test_calculate_values
    prepare_sample_catagory_tree_for_jarek
    category1 = @jarek.asset
    category2 = @jarek.loan
    test_category = @jarek.categories.find_by_name 'test'

    result = category1.calculate_values(:category_and_subcategories, :none, 1.year.ago.to_date, 1.year.from_now.to_date)


    assert_equal 1, result.size
    assert_equal 2, result.first.size
    assert_equal :category_and_subcategories, result.first.first
    assert_equal Money.new, result.first.second


    result = category1.calculate_values(:category_and_subcategories, :day, '26.02.2008'.to_date, '27.02.2008'.to_date)

    assert_equal 2, result.size
    assert_equal 2, result.first.size
    assert_equal :category_and_subcategories, result.first.first
    assert_equal Money.new, result.first.second
    assert_equal 2, result.second.size
    assert_equal :category_and_subcategories, result.second.first
    assert_equal Money.new, result.second.second

    save_simple_transfer(:income => category1, :outcome => category2, :day => '26.02.2008'.to_date, :currency => @zloty, :value => 123, :user => @jarek)

    result = category1.calculate_values(:category_and_subcategories, :day, '26.02.2008'.to_date, '27.02.2008'.to_date)

    assert_equal 2, result.size
    assert_equal 2, result.first.size
    assert_equal :category_and_subcategories, result.first.first
    assert_equal 123, result.first.second.value(@zloty)
    assert_equal 2, result.second.size
    assert_equal :category_and_subcategories, result.second.first
    assert_equal Money.new, result.second.second


  end



  #przykłady na jednej walucie i prostych transferach
  def test_calculate_flow_values
    

    prepare_sample_catagory_tree_for_jarek
    category1 = @jarek.categories.top.of_type(:INCOME).first
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
    category1 = @jarek.income
    category2 = @jarek.categories.find_by_name 'child1'

    assert_equal 'Przychody', category1.name_with_path
    assert_equal 'Zasoby:test:child1', category2.name_with_path

    category1.name = 'Nazwa'
    category1.save!
    category1 = Category.find category1.id
    assert_equal 'Nazwa', category1.name_with_path
    category2.name = 'NowaNazwa'
    category2.save!
    category2 = Category.find category2.id
    assert_equal 'Zasoby:test:NowaNazwa', category2.name_with_path

  end



  def test_percent_of_parent_category
    

    @jarek.multi_currency_balance_calculating_algorithm = :calculate_with_newest_exchanges
    @jarek.save!
    @jarek = User.find(@jarek.id)

    prepare_sample_catagory_tree_for_jarek

    test_category = @jarek.categories.find_by_name 'test'
    asset_category = @jarek.asset
    child1_category = @jarek.categories.find_by_name 'child1'
    loan_category = @jarek.loan


    assert_equal 0, test_category.percent_of_parent_category(1.year.ago.to_date, 1.year.from_now.to_date, true)
    assert_equal 0, test_category.percent_of_parent_category(1.year.ago.to_date, 1.year.from_now.to_date, false)

    save_simple_transfer(:income => test_category, :outcome => loan_category, :day => Date.today, :currency => @zloty, :value => 123, :user => @jarek)

    assert_equal 100, test_category.percent_of_parent_category(1.year.ago.to_date, 1.year.from_now.to_date, true)

    save_simple_transfer(:income => child1_category, :outcome => loan_category, :day => Date.today, :currency => @zloty, :value => 12, :user => @jarek)

    assert_equal 100, test_category.percent_of_parent_category(1.year.ago.to_date, 1.year.from_now.to_date, true)

    assert_equal 91.11, test_category.percent_of_parent_category(1.year.ago.to_date, 1.year.from_now.to_date, false)

    save_simple_transfer(:income => asset_category, :outcome => loan_category, :day => Date.today, :currency => @zloty, :value => 5, :user => @jarek)


    assert_equal 96.43, test_category.percent_of_parent_category(1.year.ago.to_date, 1.year.from_now.to_date, true)

    assert_equal 87.86, test_category.percent_of_parent_category(1.year.ago.to_date, 1.year.from_now.to_date, false)


    #TODO: przetestowane są tylko pozytywne ścieżki...

  end


  def test_assing_system_category
    prepare_sample_catagory_tree_for_jarek
    save_expense_category_jarek
    test_category = @jarek.categories.find_by_name 'test_expense'
    e = SystemCategory.create :name => 'Expenses', :category_type => :EXPENSE
    test_category.system_categories << e
    e.save!
    test_category.save!
    test_category.reload
    assert_equal [e.id], test_category.system_categories.map{|q| q.id }
  end


  def test_set_system_categories
    prepare_sample_catagory_tree_for_jarek
    prepare_sample_system_category_tree
    save_expense_category_jarek
    test_category = @jarek.categories.find_by_name 'test_expense'

    system_category = SystemCategory.find_by_name 'Fruits'
    test_category.system_category = system_category
    test_category.save!
    assert_equal system_category.self_and_ancestors.map{|s|s.id}.sort, test_category.system_categories.map{|c|c.id}.sort

    test_category.system_category_id = system_category.id
    test_category.save!
    assert_equal system_category.self_and_ancestors.map{|s|s.id}.sort, test_category.system_categories.map{|c|c.id}.sort


    system_category = SystemCategory.find_by_name 'Expenses'
    test_category.system_category = system_category
    test_category.save!
    assert_equal system_category.self_and_ancestors.map{|s|s.id}.sort, test_category.system_categories.map{|c|c.id}.sort

    test_category.system_category_id = system_category.id
    test_category.save!
    assert_equal system_category.self_and_ancestors.map{|s|s.id}.sort, test_category.system_categories.map{|c|c.id}.sort


    test_category.system_category = nil
    test_category.save!
    assert_equal [], test_category.system_categories

    test_category.system_category_id = nil
    test_category.save!
    assert_equal [], test_category.system_categories

  end


  def test_get_system_categories
    prepare_sample_catagory_tree_for_jarek
    prepare_sample_system_category_tree
    save_expense_category_jarek
    test_category = @jarek.categories.find_by_name 'test_expense'

    system_category = SystemCategory.find_by_name 'Fruits'
    
    test_category.system_category = system_category
    test_category.save!
    assert_equal system_category.id, test_category.system_category.id
    assert_equal system_category.id, test_category.system_category_id

    system_category = SystemCategory.find_by_name 'Expenses'
    test_category.system_category = system_category
    test_category.save!
    assert_equal system_category.id, test_category.system_category.id
    assert_equal system_category.id, test_category.system_category_id

    test_category.system_category = nil
    test_category.save!
    assert_nil test_category.system_category
    assert_nil test_category.system_category_id


  end


  test "system_category_type_validation" do
    prepare_sample_catagory_tree_for_jarek
    prepare_sample_system_category_tree
    test_category = @jarek.categories.find_by_name 'test'

    system_category = SystemCategory.find_by_name 'Fruits'

    test_category.system_category = system_category
    assert !test_category.save
    assert_match(/systemowa powinna być tego samego typu/, test_category.errors.on(:base))

  end


  test "Category autocomplete" do
    prepare_sample_system_category_tree
    jarek_loan = @jarek.loan
    jarek_expense = @jarek.expense
    jarek_food = Category.new(:name => 'Food', :parent => jarek_expense, :user => @jarek)
    jarek_food.save!

    jarek_yoghurt = Category.new(:name => 'Yoghurt', :parent => jarek_food, :user => @jarek)
    jarek_yoghurt.save!

    rupert_expense = @rupert.expense
    rupert_alcohol = Category.new(:name => 'Alcohol', :parent => rupert_expense, :user => @rupert)
    rupert_alcohol.save!

    rupert_dairy = Category.new(:name => 'Dairy Products', :parent => rupert_expense, :user => @rupert)
    rupert_dairy.save!

    rupert_loan = @rupert.loan
    rupert_girlfriend = Category.new(:name => 'Girlfriend', :parent => rupert_loan, :user => @rupert)
    rupert_girlfriend.save!


    save_simple_transfer(:user => @jarek, :description => 'shoes', :income => jarek_expense)
    save_simple_transfer(:user => @rupert, :description => 'clothes', :income => rupert_expense)
    save_simple_transfer(:user => @jarek, :description => 'danone', :income => jarek_yoghurt)
    save_simple_transfer(:user => @rupert, :description => 'wine', :income => rupert_alcohol)
    save_simple_transfer(:user => @rupert, :description => 'Lend for buying some wine', :income => rupert_girlfriend)

    Category.class_eval do
      def sys_cat(text_or_nil)
        self.system_category = text_or_nil.is_a?(String) ? SystemCategory.find_by_name!(text_or_nil) : nil
        save!
      end
    end

    def TransferItem.search_for_ids(text)
      TransferItem.find(:all).to_a.select{|ti| ti.description =~ Regexp.new(text)}.map(&:id)
    end
    
    assert Category.autocomplete('clothes', @rupert).empty?
    assert Category.autocomplete('clothes', @jarek).empty?

    jarek_expense.sys_cat('Expenses')
    assert_not_nil jarek_expense.system_category

    assert Category.autocomplete('clothes', @rupert).empty?
    assert Category.autocomplete('clothes', @jarek).empty?

    jarek_expense.sys_cat(nil)
    rupert_expense.sys_cat('Expenses')
    assert Category.autocomplete('clothes', @rupert).empty?
    assert Category.autocomplete('clothes', @jarek).empty?

    jarek_expense.sys_cat('Expenses')
    rupert_expense.sys_cat('Expenses')

    assert Category.autocomplete('wine', @rupert).empty?
    assert Category.autocomplete('wine', @jarek).empty?

    assert Category.autocomplete('danone', @rupert).empty?
    assert Category.autocomplete('danone', @jarek).empty?

    assert Category.autocomplete('clothes', @rupert).empty?
    assert_equal [jarek_expense], Category.autocomplete('clothes', @jarek)

    assert Category.autocomplete('shoes', @jarek).empty?
    assert_equal [jarek_expense], Category.autocomplete('shoes', @rupert)

    jarek_yoghurt.sys_cat('Yoghurt')
    assert_equal [rupert_expense], Category.autocomplete('danone', @rupert)
    assert Category.autocomplete('danone', @jarek).empty?

    rupert_dairy.sys_cat('Dairy Products')
    assert_equal [rupert_expense, rupert_dairy].to_set, Category.autocomplete('danone', @rupert).to_set
    assert Category.autocomplete('danone', @jarek).empty?

    rupert_alcohol.sys_cat('Alcohol')
    assert_equal [jarek_expense], Category.autocomplete('wine', @jarek)
    assert Category.autocomplete('wine', @rupert).empty?

    jarek_food.sys_cat('Food')
    assert_equal [jarek_expense, jarek_food].to_set, Category.autocomplete('wine', @jarek).to_set
    assert Category.autocomplete('wine', @rupert).empty?

    rupert_girlfriend.sys_cat('Loan')
    assert_equal [jarek_expense, jarek_food].to_set, Category.autocomplete('wine', @jarek).to_set
    assert Category.autocomplete('wine', @rupert).empty?

    jarek_loan.sys_cat('Loan')
    assert_equal [jarek_expense, jarek_food, jarek_loan].to_set, Category.autocomplete('wine', @jarek).to_set
    assert Category.autocomplete('wine', @rupert).empty?
  end


  test "save_new_subcategories with one subcategory" do
    prepare_sample_catagory_tree_for_jarek
    prepare_sample_system_category_tree
    save_expense_category_jarek
    test_category = @jarek.categories.find_by_name 'test_expense'
    system_category = SystemCategory.find_by_name 'Fruits'
    test_category.new_subcategories = [system_category.id]
    assert_difference("@jarek.categories.count", +1) do
      test_category.save_new_subcategories!
    end
    new_category = Category.find_by_name 'Fruits'
    assert_not_nil new_category
    assert_equal(new_category.parent, test_category)
    assert_equal(new_category.system_category, system_category)
  end



  test "save_new_subcategories with one category with parent" do
    prepare_sample_catagory_tree_for_jarek
    prepare_sample_system_category_tree
    save_expense_category_jarek
    test_category = @jarek.categories.find_by_name 'test_expense'
    system_category1 = SystemCategory.find_by_name 'Fruits'
    system_category2 = system_category1.parent
    test_category.new_subcategories = [system_category1.id, system_category2.id]

    assert_difference("@jarek.categories.count", +2) do
      test_category.save_new_subcategories!
    end

    new_category2 = Category.find_by_name system_category2.name
    assert_not_nil new_category2
    assert_equal(new_category2.parent, test_category)
    assert_equal(new_category2.system_category, system_category2)


    new_category = Category.find_by_name 'Fruits'
    assert_not_nil new_category
    assert_equal(new_category.parent, new_category2)
    assert_equal(new_category.system_category, system_category1)

  end


  test "save_new_subcategories with one top category" do
    prepare_sample_catagory_tree_for_jarek
    prepare_sample_system_category_tree
    save_expense_category_jarek
    test_category = @jarek.categories.find_by_name 'test_expense'
    system_category1 = SystemCategory.find_by_name 'Expenses'
    test_category.new_subcategories = [system_category1.id]


    assert_difference("@jarek.categories.count", +1) do
      test_category.save_new_subcategories!
    end

    new_category = Category.find_by_name system_category1.name
    assert_not_nil new_category
    assert_equal(new_category.parent, test_category)
    assert_equal(new_category.system_category, system_category1)

  end


  test "save_new_subcategories with many categories" do
    prepare_sample_catagory_tree_for_jarek
    prepare_sample_system_category_tree
    save_expense_category_jarek
    test_category = @jarek.categories.find_by_name 'test_expense'
    system_category1 = SystemCategory.find_by_name 'Fruits'
    system_category2 = system_category1.parent.parent
    system_category3 = SystemCategory.find_by_name 'Clothes'
    test_category.new_subcategories = [system_category1.id, system_category2.id, system_category3.id]

    assert_difference("@jarek.categories.count", +3) do
      test_category.save_new_subcategories!
    end

    new_category2 = Category.find_by_name system_category2.name
    assert_not_nil new_category2
    assert_equal(new_category2.parent, test_category)
    assert_equal(new_category2.system_category, system_category2)

    new_category3 = Category.find_by_name system_category3.name
    assert_not_nil new_category3
    assert_equal(new_category3.parent, new_category2)
    assert_equal(new_category3.system_category, system_category3)

    new_category = Category.find_by_name system_category1.name
    assert_not_nil new_category
    assert_equal(new_category.parent, new_category2)
    assert_equal(new_category.system_category, system_category1)

  end



  test "save_new_subcategories with one category havin wrong type" do
    prepare_sample_catagory_tree_for_jarek
    prepare_sample_system_category_tree
    save_expense_category_jarek
    test_category = @jarek.categories.find_by_name 'test_expense'
    system_category1 = SystemCategory.find_by_name 'Cash'
    test_category.new_subcategories = [system_category1.id]


    assert_no_difference("@jarek.categories.count") do
      assert_raise ActiveRecord::RecordInvalid do
        test_category.save_new_subcategories!
      end
    end

  end

  test "With_level scope or without" do
    prepare_sample_catagory_tree_for_jarek

    [@jarek.categories.with_level.find_by_name('test'),
      @jarek.categories.find_by_name('test')].each do |cat|
      assert_equal cat.level, cat.cached_level
      assert_equal 1, cat.cached_level
    end

    [@jarek.categories.with_level.find_by_name(@jarek.asset.name),
      @jarek.categories.find_by_name(@jarek.asset.name)].each do |cat|
      assert_equal cat.level, cat.cached_level
      assert_equal 0, cat.cached_level
    end

  end


  test "Building sql group clause for compute method" do
    sql="CASE
WHEN transfers.day <= '2008-01-31' THEN 0
WHEN transfers.day <= '2008-02-29' THEN 1
WHEN transfers.day <= '2008-03-31' THEN 2
WHEN transfers.day <= '2008-04-30' THEN 3
WHEN transfers.day <= '2008-05-31' THEN 4
END as my_group,
    "

    assert_equal sql.strip, Category.send(:build_my_group, Date.split_period(:month, '2008-01-01'.to_date, '2008-05-31'.to_date)).strip
    
    sql="CASE
WHEN transfers.day <= '2008-01-31' THEN 0
WHEN transfers.day <= '2008-02-29' THEN 1
END as my_group,
    "
    assert_equal sql.strip, Category.send(:build_my_group, [Range.new('2008-01-01'.to_date, '2008-01-31'.to_date), Range.new('2008-02-01'.to_date, '2008-02-29'.to_date)]).strip

    sql = "0 as my_group,\n"

    assert_equal sql, Category.send(:build_my_group, Range.new('2008-01-01'.to_date, '2008-01-31'.to_date))
    assert_equal sql, Category.send(:build_my_group, '2008-01-31'.to_date)
    assert_equal sql, Category.send(:build_my_group, nil)
  end


  test "Building sql where clause for compute method" do
    category = @rupert.asset
    sql="
    WHERE categories.user_id = #{@rupert.id} AND
    categories.id IN ( #{category.id} ) AND
    transfers.day >= '2008-01-01' AND transfers.day <= '2008-05-31'
    "

    String.class_eval do
      def unified_sql
        self.gsub("\n","").gsub(/\s+/, ' ').strip
      end
    end

    assert_equal sql.unified_sql, Category.send(:build_where, @rupert, [category], Date.split_period(:month, '2008-01-01'.to_date, '2008-05-31'.to_date)).unified_sql

    sql="
    WHERE categories.user_id = #{@rupert.id} AND
    categories.id IN ( #{@rupert.categories.map(&:id).join(', ')} ) AND
    transfers.day >= '2008-02-01' AND transfers.day <= '2008-06-30'
    "

    assert_equal sql.unified_sql, Category.send(:build_where, @rupert, @rupert.categories, Range.new('2008-02-01'.to_date, '2008-06-30'.to_date)).unified_sql

    sql="
    WHERE categories.user_id = #{@rupert.id} AND
    categories.id IN ( #{@rupert.categories.map(&:id).join(', ')} ) AND
    transfers.day <= '2008-12-31'
    "

    assert_equal sql.unified_sql, Category.send(:build_where, @rupert, @rupert.categories, '2008-12-31'.to_date).unified_sql    
    assert_equal sql.unified_sql, Category.send(:build_where, @rupert, @rupert.categories, '2008-12-31'.to_date.to_time + 23.hours).unified_sql

    sql="
    WHERE categories.user_id = #{@rupert.id} AND
    categories.id IN ( #{@rupert.categories.map(&:id).join(', ')} )"

    assert_equal sql.unified_sql, Category.send(:build_where, @rupert, @rupert.categories, nil).unified_sql
  end


  test "cool stuff" do
    
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


  def save_expense_category_jarek
    parent = @jarek.expense
    category = Category.new(
      :name => 'test_expense',
      :description => 'test',
      :user => @jarek,
      :parent => parent
    )

    @jarek.categories << category
    @jarek.save!
  end

  
end
