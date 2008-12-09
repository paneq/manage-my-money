require File.dirname(__FILE__) + '/../test_helper'
require 'categories_controller'

# Re-raise errors caught by the controller.
class CategoryController; def rescue_action(e) raise e end; end

class CategoryControllerTest < Test::Unit::TestCase

  def setup
    @controller = CategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    save_currencies
    save_rupert
    log_rupert
  end


  #TODO poprawic by sprawdzal kiedy nie tylko domyslne kategorie ale tez dodatkowe. Ze wtedy ta dodatkowa jest w odpowiednim miejscu, nie ostatnia a wewnatrz ktorejs
  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    
    assert_select 'div#categories-index' do
      assert_select 'div#category-tree' do
        assert_select 'div#category-line', @rupert.categories.count
      end
      @rupert.categories.count.times do |nr|
        assert_select "div#category-tree div:nth-child(#{nr+1})" do
          assert_select "span#category-link" do
            assert_select "a > a", Regexp.new("#{@rupert.categories[nr].name}")
          end
        end
      end
    end
  end


  def test_new
    get :new 
    assert_response :success
    assert_template 'new'
    assert_select 'div#category-edit' do
      assert_select 'p#name', 1
      assert_select 'p#description', 1
      assert_select 'p#parent', 1
      assert_select 'p#balance' do
        assert_select 'span#currency'
      end
      assert_select 'p#create', 1
    end
    @rupert.categories.count.times do |nr|
      assert_select "select#parent-select option:nth-child(#{nr+1})", Regexp.new("#{@rupert.categories[nr].name}")
    end
    @rupert.visible_currencies.count.times do |nr|
      assert_select "select#currency-select option:nth-child(#{nr+1})", Regexp.new("#{@rupert.visible_currencies[nr].long_name}")
    end
  end


  def test_proper_selcted_element_when_new_with_given_parent_category
    parent_category = @rupert.categories.top_of_type(:EXPENSE)
    get :new, :parent_category_id => parent_category.id
    assert_response :success
    assert_template 'new'
    assert_select 'div#category-edit' do
      assert_select 'option[selected=selected]', parent_category.name
    end
  end

  
  def test_create
    parent_category = @rupert.categories.top_of_type(:INCOME)
    post :create, :category => {
      :name => 'test name',
      :description => 'test description',
      :parent => parent_category.id,
      :opening_balance => '1 200',
      :opening_balance_currency => @zloty.id
    }
    assert_redirected_to :action => :index

    created_category = @rupert.categories.find_by_name('test name')
    assert_not_nil created_category
    assert_equal parent_category, created_category.parent
    assert created_category.saldo_at_end_of_day(Date.today).currencies.include?(@zloty)
    assert_equal 1200, created_category.saldo_at_end_of_day(Date.today).value(@zloty)
  end


  def test_edit_top_category
    get :edit, :id => @rupert.categories.top_of_type(:INCOME)
    assert_response :success
    assert_template 'edit'
    assert_select 'div#category-edit' do
      assert_select 'p#name', 1
      assert_select 'p#description', 1
      assert_select 'p#parent', 0
      assert_select 'p#update', 1
    end
  end


  def test_edit_non_top_category
    create_rupert_expenses_account_structure

    get :edit, :id => @food.id
    assert_response :success
    assert_template 'edit'
    assert_select 'div#category-edit' do
      assert_select 'p#parent', 1
      assert_select 'option[selected=selected]', @expense_category.name
    end
    [@expense_category, @house, @rent, @clothes].each_with_index do |c, nr|
      assert_select "select#parent-select option:nth-child(#{nr+1})", Regexp.new(c.name)
    end
  end


  def test_update_top_category
    income_category = @rupert.categories.top_of_type(:EXPENSE)
    loan_category = @rupert.categories.top_of_type(:LOAN)

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

    #changing name, description and parent should pass
    @healthy = @rupert.categories.find(@healthy.id) #newset version of category
    assert_equal 'new_healthy_name', @healthy.name
    assert_equal 'new_healthy_description', @healthy.description
    assert_equal @expense_category, @healthy.parent

    #changing type should failed
    assert_equal :EXPENSE, @healthy.category_type

  end

  #TODO: testy przy podawaniu zlych danych, np kiedy proba przeniesienia kategorii do takiej gdzie przeniesc nie mozna.

  def test_destroy

  end


  private
  
  def create_rupert_expenses_account_structure
    # EXPENSE -            [SELECTED]
    #         |- food      [EDITED]
    #         |-- healthy
    #         |- house
    #         |-- rent
    #         |- clothes

    @expense_category = @rupert.categories.top_of_type(:EXPENSE)
    @loan_category = @rupert.categories.top_of_type(:LOAN)

    @food = Category.new(
      :name => 'food',
      :parent => @expense_category,
      :user => @rupert
    )
    @house = Category.new(
      :name => 'house',
      :parent => @expense_category,
      :user => @rupert
    )
    @clothes = Category.new(
      :name => 'clothes',
      :parent => @expense_category,
      :user => @rupert
    )
    @healthy = Category.new(
      :name => 'healthy',
      :parent => @food,
      :user => @rupert
    )
    @rent = Category.new(
      :name => 'rent',
      :parent => @house,
      :user => @rupert
    )
    @rupert.categories << @food << @house << @clothes << @healthy << @rent
    @rupert.save!
  end
end
