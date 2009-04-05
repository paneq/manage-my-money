require 'test_helper'

# Re-raise errors caught by the controller.
class CategoriesController; def rescue_action(e) raise e end; end

class CategoriesControllerTest < ActionController::TestCase

  def setup

    prepare_currencies
    save_rupert
    save_jarek
    prepare_sample_system_category_tree
    log_rupert
  end


  def test_index
    #Test page rendered
    get :index
    assert_response :success
    assert_template 'index'


    assert_select 'div#categories-index' do
      assert_select 'table#category-tree' do
        assert_select 'tr[id^=category-line]', @rupert.categories.count
      end
      @rupert.categories.count.times do |nr|
        category = @rupert.categories[nr]

        #test categories in valid order
        assert_select "table#category-tree tr:nth-child(#{nr+1+1})" do
          assert_select "td#category-link" do
            assert_select "a > a", Regexp.new("#{category.name}")
          end

          #test place for saldo
          assert_select "td#category-saldo-#{category.id}"

          #test options
          assert_select "td#category-options" do

            #add subcategory link
            assert_select "a#add-subc-#{category.id}"
          end
        end
      end
    end
  end


  #Test that only non top categories have link to delete them
  def test_index_del_elements
    create_rupert_expenses_account_structure
    get :index
    assert_response :success
    assert_template 'index'
    assert_select 'a[id^=dest-cat]', rupert.categories.count - 5
    @rupert.categories.count.times do |nr|
      category = @rupert.categories[nr]
      assert_select "table#category-tree tr:nth-child(#{nr+1+1})" do
        occures = category.is_top? ? 0 : 1
        assert_select "td#category-options" do
          assert_select "a#dest-cat-#{category.id}", occures
        end
      end
    end
  end



  def test_new
    #Test page rendered
    get :new 
    assert_response :success
    assert_template 'new'

    #test fields for editing
    assert_select 'div#category-edit' do
      assert_select 'p#name', 1
      assert_select 'p#description', 1
      assert_select 'p#parent', 1
      assert_select 'p#balance' do
        assert_select 'span#currency'
      end
      assert_select 'p#create', 1
    end

    #test all already existing categories can be choosen for parent
    @rupert.categories.count.times do |nr|
      assert_select "select#parent-select option:nth-child(#{nr+1})", Regexp.new("#{@rupert.categories[nr].name}")
    end

    #test all currencies can be choosen
    @rupert.visible_currencies.count.times do |nr|
      assert_select "select#currency-select option:nth-child(#{nr+1})", Regexp.new("#{@rupert.visible_currencies[nr].long_name}")
    end

    #test all user categories can be choosen
    @rupert.categories.count.times do |nr|
      assert_select "select#parent-select option:nth-child(#{nr+1})", Regexp.new("#{@rupert.categories[nr].name}")
    end


    sys_categories = SystemCategory.all

    assert sys_categories.size > 0

    assert_select 'select#system-category-select' do
      assert_select "option", :count => (SystemCategory.count + 1) do
        sys_categories.each do |opt|
          assert_select "option[value=#{opt.id}]"
        end
        assert_select 'option', 'Brak'
      end
    end

    assert_new_subcategories(sys_categories)

  end

  # test if proper parent_category is selected when user came to the site
  # from link to create subcategory of some category
  def test_new_and_proper_selected_element_when_given_parent_category
    parent_category = @rupert.expense
    get :new, :parent_category_id => parent_category.id
    assert_response :success
    assert_template 'new'
    assert_select 'div#category-edit' do
      assert_select 'option[selected=selected]', parent_category.name
    end
  end

  
  def test_create
    parent_category = @rupert.income
    post :create, :category => {
      :name => 'test name',
      :description => 'test description',
      :parent => parent_category.id,
      :opening_balance => '1 200',
      :opening_balance_currency_id => @zloty.id,
      :system_category_id => ''
    }
    assert_redirected_to :action => :index

    created_category = @rupert.categories.find_by_name('test name')
    assert_not_nil created_category
    assert_equal parent_category, created_category.parent
    assert created_category.saldo_at_end_of_day(Date.today).currencies.include?(@zloty)
    assert_equal 1200, created_category.saldo_at_end_of_day(Date.today).value(@zloty)
    assert_nil created_category.system_category
  end


  def test_create_with_system_category
    system_food = SystemCategory.find_by_name('Food')
    parent_category = @rupert.expense
    post :create, :category => {
      :name => 'test name',
      :description => 'test description',
      :parent => parent_category.id,
      :opening_balance => '1 200',
      :system_category_id => system_food.id,
      :opening_balance_currency_id => @zloty.id
    }
    assert_redirected_to :action => :index

    created_category = @rupert.categories.find_by_name('test name')
    assert_not_nil created_category
    assert_equal parent_category, created_category.parent
    assert_equal system_food.id, created_category.system_category.id
  end


  def test_create_with_float_opening_balance
    parent_category = @rupert.income
    post :create, :category => {
      :name => 'test name',
      :description => 'test description',
      :parent => parent_category.id,
      :opening_balance => '1234.56',
      :opening_balance_currency_id => @zloty.id
    }
    assert_redirected_to :action => :index

    created_category = @rupert.categories.find_by_name('test name')
    assert_not_nil created_category
    assert_equal parent_category, created_category.parent
    assert created_category.saldo_at_end_of_day(Date.today).currencies.include?(@zloty)
    assert_equal 1234.56 , created_category.saldo_at_end_of_day(Date.today).value(@zloty)
  end


  def test_create_with_errors
    parent_category = @rupert.income
    post :create, :category => {
      #no name given
      :description => 'test description',
      :parent => parent_category.id,
    }
    assert_response :success
    assert_template 'new'

    assert_select "input#category_description[value='test description']", 1
    assert_select 'div#category-edit' do
      assert_select 'option[selected=selected]', parent_category.name
    end
    assert_match(/Nie udało.*/, flash[:notice])


    post :create, :category => {
      :name => 'test name',
      :description => 'test description',
      :parent => parent_category.id,
      :opening_balance => 'YXZ',
      :opening_balance_currency_id => @euro.id
    }
    assert_response :success
    assert_template 'new'

    assert_select "input#category_name[value='test name']"
    assert_select "select#currency-select" do
      assert_select "option[value=#{@euro.id}][selected=selected]"
    end
    assert_match(/Nie udało.*/, flash[:notice])

  end


  def test_create_with_subcategories
    parent_category = @rupert.expense
    system_food = SystemCategory.find_by_name('Food')
    assert_difference("@rupert.categories.count", +2) do
      post :create, :category => {
        :name => 'test name',
        :parent => parent_category.id,
        :system_category_id => '',
        :new_subcategories => [system_food.id]
      }
    
    end

    assert_redirected_to :action => :index

    created_category = @rupert.categories.find_by_name('test name')
    assert_not_nil created_category
    assert_equal parent_category, created_category.parent

    created_subcategory = @rupert.categories.find_by_name('Food')
    assert_not_nil created_subcategory
    assert_equal created_category, created_subcategory.parent

  end


  def test_create_with_subcategories_with_validation
    parent_category = @rupert.income
    system_food = SystemCategory.find_by_name('Food')
    assert_no_difference("@rupert.categories.count") do
      post :create, :category => {
        :name => 'test name',
        :parent => parent_category.id,
        :system_category_id => '',
        :new_subcategories => [system_food.id]
      }

    end

    assert_response :success
    assert_template 'new'
    assert_match(/Nie udało.*/, flash[:notice])
  end




  def test_edit_top_category
    get :edit, :id => @rupert.income
    assert_response :success
    assert_template 'edit'
    assert_select 'div#category-edit' do
      assert_select 'p#name', 1
      assert_select 'p#description', 1
      assert_select 'p#parent', 0
      assert_select 'p#loan', 0
      assert_select 'p#update', 1
    end
    assert_select "input#category_name[value='#{@rupert.income.name}']"
    assert_select "input#category_description[value='#{@rupert.income.description}']"
  end


  def test_edit_non_top_category
    create_rupert_expenses_account_structure

    get :edit, :id => @food.id
    assert_response :success
    assert_template 'edit'
    assert_select 'div#category-edit' do
      assert_select 'label#parent', 1
      assert_select 'p#loan', 0
      assert_select 'option[selected=selected]', @expense_category.name
    end
    [@expense_category, @house, @rent, @clothes].each_with_index do |c, nr|
      assert_select "select#parent-select option:nth-child(#{nr+1})", Regexp.new(c.name)
    end

    @rupert.categories.build(:name => 'test', :parent => rupert.loan)
    @rupert.save!

    get :edit, :id => @rupert.loan.children.first
    assert_response :success
    assert_template 'edit'
    assert_select 'div#category-edit' do
      assert_select 'p#loan' do
        assert_select 'p#is_loan', 1
        assert_select 'p#email', 1
        assert_select 'p#bankinfo', 1
        assert_select 'p#bank_account_number', 1
      end
    end
  end

  def test_edit_select_system_category
    create_rupert_expenses_account_structure
    system_food = SystemCategory.find_by_name('Food')
    @food.system_category = system_food
    @food.save!
    get :edit, :id => @food.id
    assert_response :success
    assert_template 'edit'


    sys_categories = SystemCategory.of_type(:EXPENSE)

    assert sys_categories.size > 0

    assert_select 'select#system-category-select' do
      assert_select "option", :count => (SystemCategory.of_type(:EXPENSE).count + 1) do
        sys_categories.each do |opt|
          assert_select "option[value=#{opt.id}]"
        end
        assert_select "option[value=#{system_food.id}][selected=selected]", system_food.name_with_indentation
      end
    end

    assert_new_subcategories(sys_categories)

    subcategories = @food.descendants
    assert_select 'div#current-subcategories' do
      assert_select "label", :count => subcategories.size do
        subcategories.each do |sc|
          assert_select "label#cur-subcategory-#{sc.id}", sc.name
        end
      end
    end
  end


  def test_edit_with_no_subcategories
    create_rupert_expenses_account_structure
    get :edit, :id => @rupert.income.id
    assert_response :success
    assert_template 'edit'

    subcategories = @rupert.income.descendants
    assert_equal 0, subcategories.size

    assert_select 'div#current-subcategories' do
      assert_select "label", :count => 0
      assert_select "p", 'Brak'
    end
  end


  def test_update_top_category
    income_category = @rupert.income
    loan_category = @rupert.loan

    put :update, :id => loan_category.id, :category => {
      :name => 'new_loan_name',
      :description => 'new_loan_description',
      :category_type_int => income_category.category_type_int,
      :parent => income_category.id,
      :system_category_id => ''
    }

    assert_redirected_to :action => :show

    #chaning name and description should pass
    loan_category = @rupert.categories.find(loan_category.id) #newset version of category
    assert_equal 'new_loan_name', loan_category.name
    assert_equal 'new_loan_description', loan_category.description

    #changing type and parent should failed
    assert loan_category.is_top?
    assert_equal :LOAN, loan_category.category_type

  end


  def test_update_non_top_category
    create_rupert_expenses_account_structure

    put :update, :id => @healthy.id, :category => {
      :name => 'new_healthy_name',
      :description => 'new_healthy_description',
      :parent => @expense_category.id,
      :category_type_int => @loan_category.category_type_int,
      :system_category_id => ''
    }

    assert_redirected_to :action => :show
    assert_match(/Zapisano/, flash[:notice])

    #changing name, description and parent should pass
    @healthy = @rupert.categories.find(@healthy.id) #newset version of category
    assert_equal 'new_healthy_name', @healthy.name
    assert_equal 'new_healthy_description', @healthy.description
    assert_nil @healthy.system_category
    assert_equal @expense_category, @healthy.parent

    #changing type should failed
    assert_equal :EXPENSE, @healthy.category_type

  end

  def test_update_with_system_category
    create_rupert_expenses_account_structure
    system_food = SystemCategory.find_by_name('Food')
    parent_category = @rupert.expense
    put :update, :id => @healthy.id, :category => {
      :name => 'test name',
      :description => 'test description',
      :parent => parent_category.id,
      :system_category_id => system_food.id,
    }
    assert_redirected_to :action => :show

    updated_category = @rupert.categories.find_by_name('test name')
    assert_equal system_food.id, updated_category.system_category.id
  end

  def test_update_with_subcategories
    create_rupert_expenses_account_structure
    system_food = SystemCategory.find_by_name('Food')
    parent_category = @rupert.expense
    assert_difference("@rupert.categories.count", +1) do
      put :update, :id => @healthy.id, :category => {
        :name => 'test name',
        :parent => parent_category.id,
        :new_subcategories => [system_food.id]
      }

    end
    assert_redirected_to :action => :show

    updated_category = @rupert.categories.find_by_name('test name')
    assert_not_nil updated_category


    created_category = @rupert.categories.find_by_name('Food')
    assert_not_nil created_category
    assert_equal updated_category, created_category.parent

  end

  def test_update_with_subcategories_and_validation
    create_rupert_expenses_account_structure
    system_food = SystemCategory.find_by_name('Food')
    assert_no_difference("@rupert.categories.count") do
      put :update, :id => @rupert.income.id, :category => {
        :name => 'test name',
        :new_subcategories => [system_food.id]
      }
    end

    assert_response :success
    assert_template 'edit'
    assert_match(/Nie udało.*/, flash[:notice])
  end




  def test_update_to_loan
    category = Category.new(:name => 'sejtenik', :parent => rupert.loan, :user => @rupert)
    category.save!

    put :update, :id => category.id, :category => {
      :loan_category => '1',
      :email => 'sejtenik@gmail.com',
      :bankinfo => 'bank bank bank'
    }

    assert_redirected_to :action => :show
    assert_match(/Zapisano/, flash[:notice])

    category = rupert.categories(true).people_loans.find_by_id(category.id)
    assert_not_nil category
    assert !category.email.blank?
    assert !category.bankinfo.blank?

    put :update, :id => category.id, :category => {
      :loan_category => '0'
    }
    
    category = rupert.categories.people_loans.find_by_id(category.id)
    assert_nil category
  end


  #TODO: testy przy podawaniu zlych danych, np kiedy proba przeniesienia kategorii do takiej gdzie przeniesc nie mozna.

  def test_destroy_non_top_category
    create_rupert_expenses_account_structure
    delete :destroy, :id => @food
    assert_redirected_to :action => :index, :controller => :categories
    assert_match "Usunięto", flash[:notice]
  end


  def test_destroy_top_category
    delete :destroy, :id => @rupert.expense
    assert_redirected_to :action => :index, :controller => :categories
    assert_match("Nie można", flash[:notice])
  end


  def test_show
    
  end


  def test_show_menu
    get :show, :id => @rupert.categories.top.of_type(:EXPENSE).find(:first)
    assert_tab ['quick', 'full', 'search'], :transfer
    assert_transfer_pages('/categories/search')
  end


  # security tests
  def test_invisible_to_others
    [[:show,:get], [:search, :post], [:destroy, :delete], [:edit, :get], [:update, :put]].each do |action, method|
      send(method, action, :id => @jarek.asset.id)
      assert_redirected_to :action => :index, :controller => :categories
      assert_match("Brak uprawnień", flash[:notice])
    end

    assert_no_difference("@jarek.categories.count") do
      try_create(
        :name => 'bad category',
        :user_id => @jarek.id,
        :parent => @rupert.asset.id)
      assert_no_difference("@rupert.categories.count") do
        try_create(
          :name => 'bad category',
          :user_id => @jarek.id,
          :parent => @jarek.asset.id)
        try_create(
          :name => 'bad category',
          :user_id => @jarek.id,
          :category_type_int => @jarek.asset.category_type_int)
        try_create(
          :name => 'bad category',
          :user_id => @jarek.id)
      end
    end
    
  end


  private


  def assert_new_subcategories(sys_categories)
    assert_select 'div#new-subcategories' do
      assert_select "input[type='checkbox']", :count => sys_categories.size
      sys_categories.each do |opt|
        assert_select "input#sub-category-#{opt.id}[value='#{opt.id}']"
        assert_select "label[for='sub-category-#{opt.id}']", opt.name
      end
    end
  end


  def try_create(hash)
    begin
      post :create, :category => hash
    rescue
    end
  end
end
