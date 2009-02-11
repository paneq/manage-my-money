require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :users

  def test_should_create_user
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end


  def test_should_initialize_activation_code_upon_creation
    user = create_user
    user.reload
    assert_not_nil user.activation_code
  end


  def test_should_require_login
    assert_no_difference 'User.count' do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end


  def test_should_require_password
    assert_no_difference 'User.count' do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end


  def test_should_require_password_confirmation
    assert_no_difference 'User.count' do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end


  def test_should_require_email
    assert_no_difference 'User.count' do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end


  def test_should_reset_password
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin', 'new password')
  end


  def test_should_not_rehash_password
    users(:quentin).update_attributes(:login => 'quentin2')
    assert_equal users(:quentin), User.authenticate('quentin2', 'test')
  end


  def test_should_authenticate_user
    assert_equal users(:quentin), User.authenticate('quentin', 'test')
  end


  def test_should_set_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
  end


  def test_should_unset_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    users(:quentin).forget_me
    assert_nil users(:quentin).remember_token
  end


  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    users(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end


  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:quentin).remember_me_until time
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert_equal users(:quentin).remember_token_expires_at, time
  end


  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    users(:quentin).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end


  def test_should_have_required_categories_after_created
    save_rupert
    assert_equal 5, @rupert.categories.count, "User should have 5 categories after creation"
  end


  def test_should_find_top_category_of_type
    save_rupert
    base_categories = @rupert.categories.clone
    @rupert.categories.each do |category|
      assert_equal category, @rupert.categories.top_of_type(category.category_type)
    end

    @parent = @rupert.categories.top_of_type(:EXPENSE)
    category = Category.new(:name => 'test', :description => 'test', :category_type => :EXPENSE, :user => @rupert, :parent => @parent)
    @rupert.categories << category
    @rupert.save!

    assert_equal 5, base_categories.size
    assert_equal 6, @rupert.categories.count
    assert_equal base_categories.find{|c| c.category_type == :EXPENSE}, @rupert.categories.top_of_type(:EXPENSE)

    @parent = @rupert.categories.top_of_type(:EXPENSE)
    category = Category.new(:name => 'test2', :description => 'test2', :category_type => :EXPENSE, :user => @rupert, :parent => @parent)
    @rupert.categories << category
    @rupert.save!

    assert_equal 5, base_categories.size
    assert_equal 7, @rupert.categories.count
    assert_equal base_categories.find{|c| c.category_type == :EXPENSE}, @rupert.categories.top_of_type(:EXPENSE)
  end


  def test_shoud_have_categories_in_valid_order
    save_rupert
    assert_equal [:ASSET, :INCOME, :EXPENSE, :LOAN, :BALANCE], @rupert.categories.map {|c| c.category_type}

    categories_ids = @rupert.categories.map {|c| c.id}

    @parent = @rupert.categories.top_of_type(:EXPENSE)
    category = Category.new(:name => 'test', :description => 'test', :category_type => :EXPENSE, :user => @rupert)
    category.parent = @parent
    @rupert.categories << category
    @rupert.save!

    categories_ids.insert(3, category.id)
    assert_equal categories_ids, @rupert.categories(true).map {|c| c.id}
  end
  #  def test_should_not_save_user_with_no_transaction_amount_limit_value_when_needed
  #    test_user = User.new({ :login => 'quire', :email => 'quire@example.com', :password => 'komandosi', :password_confirmation => 'komandosi', :transaction_amount_limit_type => :week_count})
  #    test_user.save
  #    assert test_user.errors.on(:transaction_amount_limit_value)
  #  end

  def test_should_destroy_user
    save_rupert
    save_currencies
    rupert_id = @rupert.id

    @parent = @rupert.expense
    category = Category.new(:name => 'test', :description => 'test', :category_type => :EXPENSE, :user => @rupert, :parent => @parent)
    @rupert.categories << category


    create_share_report(@rupert)
    create_value_report(@rupert)
    create_flow_report(@rupert)

    user_currency = Currency.new(:symbol => 'A', :long_symbol => 'AAA', :name => 'aaaa', :long_name =>'aaaa aa')
    user_currency.user = @rupert
    user_currency.save!


    e = Exchange.new(:left_to_right => 1.2, :right_to_left => 0.12, :left_currency => @euro, :right_currency => @zloty, :day => Date.today, :user => @rupert)
    e.save!


    save_simple_transfer(:user => @rupert)

    @rupert.save!
    @rupert.reload

    elements = {}
    elements[:categories] = @rupert.categories.map{|cat| cat.id}
    elements[:transfers] = @rupert.transfers.map{|tr| tr.id}
    elements[:transfer_items] = @rupert.transfer_items.map{|ti| ti.id}
    elements[:reports] = @rupert.reports.map{|r| r.id}
    elements[:category_report_options] = []
    @rupert.reports.map do |r|
      if r.is_a? MultipleCategoryReport
        r.category_report_options.each { |cro| elements[:category_report_options] << cro.id }
      end
    end
#    elements[:goals] = @rupert.goals.map{|g| g.id} NOT IMLEMENTED YET
    elements[:currencies] = @rupert.currencies.map{|cur| cur.id}
    elements[:exchanges] = @rupert.exchanges.map{|exc| exc.id}

    elements.each do |key, value|
      assert value.size > 0, "Przed testem usunięcia User powinien mieć choć jeden #{key.to_s}"
    end

    assert @rupert.destroy

    assert_equal nil, User.find(:first, :conditions => {:id => rupert_id})

    elements.each do |key, value|
      model_class = key.to_s.singularize.camelcase.constantize
      values = model_class.send(:find, :all, :conditions => ['id IN (?)', value])
      assert_equal [], values, "Should destroy all #{key.to_s}"
    end


  end



  def test_top_categories_method
    save_rupert
    Category.CATEGORY_TYPES.keys.each do |category_type|
      assert_equal @rupert.categories.top_of_type(category_type), rupert.send(category_type.to_s.downcase)
    end
  end

  protected


  def create_user(options = {})
    record = User.new({ :login => 'quire', :email => 'quire@example.com', :password => 'komandosi', :password_confirmation => 'komandosi', :transaction_amount_limit_type => :actual_month }.merge(options))
    record.save
    record
  end
end
