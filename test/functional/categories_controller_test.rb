require 'test_helper'

# Re-raise errors caught by the controller.
class CategoriesController; def rescue_action(e) raise e end; end

class CategoriesControllerTest < ActionController::TestCase

  def setup

    save_currencies
    save_rupert
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
        assert_select "table#category-tree tr:nth-child(#{nr+1})" do
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
    assert_select 'a[id^=dele-subc]', rupert.categories.count - 5
    @rupert.categories.count.times do |nr|
      category = @rupert.categories[nr]
      assert_select "table#category-tree tr:nth-child(#{nr+1})" do
        occures = category.is_top? ? 0 : 1
        assert_select "td#category-options" do
          assert_select "a#dele-subc-#{category.id}", occures
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
  end

  # test if proper parent_category is selected when user came to the site
  # from link to create subcategory of some category
  def test_new_and_proper_selcted_element_when_given_parent_category
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
      :opening_balance_currency_id => @zloty.id
    }
    assert_redirected_to :action => :index

    created_category = @rupert.categories.find_by_name('test name')
    assert_not_nil created_category
    assert_equal parent_category, created_category.parent
    assert created_category.saldo_at_end_of_day(Date.today).currencies.include?(@zloty)
    assert_equal 1200, created_category.saldo_at_end_of_day(Date.today).value(@zloty)
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
      assert_select 'p#parent', 1
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
      end
    end
  end


  def test_update_top_category
    income_category = @rupert.expense
    loan_category = @rupert.loan

    put :update, :id => loan_category.id, :category => {
      :name => 'new_loan_name',
      :description => 'new_loan_description',
      :category_type => income_category.category_type,
      :category_type_int => income_category.category_type_int,
      :parent => income_category.id
    }

    assert_redirected_to :action => :index

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
      :category_type => @loan_category.category_type,
      :category_type_int => @loan_category.category_type_int
    }

    assert_redirected_to :action => :index
    assert_match(/Zapisano/, flash[:notice])

    #changing name, description and parent should pass
    @healthy = @rupert.categories.find(@healthy.id) #newset version of category
    assert_equal 'new_healthy_name', @healthy.name
    assert_equal 'new_healthy_description', @healthy.description
    assert_equal @expense_category, @healthy.parent

    #changing type should failed
    assert_equal :EXPENSE, @healthy.category_type

  end


  def test_update_to_loan
    category = Category.new(:name => 'sejtenik', :parent => rupert.loan, :user => @rupert)
    category.save!

    put :update, :id => category.id, :category => {
      :type => 'LoanCategory',
      :email => 'sejtenik@gmail.com',
      :bankinfo => 'bank bank bank'
    }

    assert_redirected_to :action => :index
    assert_match(/Zapisano/, flash[:notice])

    category = LoanCategory.find_by_id(category.id)
    assert_not_nil category
    assert !category.email.blank?
    assert !category.bankinfo.blank?

    put :update, :id => category.id, :category => {
      :type => 'Category',
    }
    
    category = LoanCategory.find_by_id(category.id)
    assert_nil category
  end


  #TODO: testy przy podawaniu zlych danych, np kiedy proba przeniesienia kategorii do takiej gdzie przeniesc nie mozna.

  def test_destroy_non_top_category
    create_rupert_expenses_account_structure
    delete :destroy, :id => @food
    assert_redirected_to :action => :index, :controller => :categories
    assert_match "Usunięto", flash[:notice]
  end


  def test_remote_destroy_non_top_category
    create_rupert_expenses_account_structure
    xhr :delete, :destroy, :id => @food
    assert_response :success
    assert_select_rjs :replace_html, 'category-tree' do
      assert_select 'tr[id^=category-line]', @rupert.categories.count
    end
    assert_select_rjs :replace_html, 'flash_notice' do
      assert_select "a", /Usunięto/
    end
  end


  def test_destroy_top_category
    delete :destroy, :id => @rupert.expense
    assert_redirected_to :action => :index, :controller => :categories
    assert_match("Nie można", flash[:notice])
  end


  def test_remote_destroy_top_category
    xhr :delete, :destroy, :id => @rupert.expense
    assert_response :success
    assert_select_rjs :replace_html, 'flash_notice' do
      assert_select "a", /Nie można/
    end

  end


  def test_show
    
  end


  def test_show_menu
    get :show, :id => @rupert.categories.top.of_type(:EXPENSE).find(:first)
    assert_tab ['quick', 'full', 'search'], :transfer
    assert_transfer_pages('/categories/search')
  end
  
end
