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

    assert created_category.saldo_at_end_of_day(Date.today).currencies.include?(@zloty)
    assert_equal 1200, created_category.saldo_at_end_of_day(Date.today).value(@zloty)
    #test wartosc
  end
  
  #  def test_list
  #    get :list
  #
  #    assert_response :success
  #    assert_template 'list'
  #
  #    assert_not_nil assigns(:categories)
  #  end
  #
  #  def test_show
  #    get :show, :id => @first_id
  #
  #    assert_response :success
  #    assert_template 'show'
  #
  #    assert_not_nil assigns(:category)
  #    assert assigns(:category).valid?
  #  end
  #
  #  def test_new
  #    get :new
  #
  #    assert_response :success
  #    assert_template 'new'
  #
  #    assert_not_nil assigns(:category)
  #  end
  #
  #  def test_create
  #    num_categories = Category.count
  #
  #    post :create, :category => {}
  #
  #    assert_response :redirect
  #    assert_redirected_to :action => 'list'
  #
  #    assert_equal num_categories + 1, Category.count
  #  end
  #
  #  def test_edit
  #    get :edit, :id => @first_id
  #
  #    assert_response :success
  #    assert_template 'edit'
  #
  #    assert_not_nil assigns(:category)
  #    assert assigns(:category).valid?
  #  end
  #
  #  def test_update
  #    post :update, :id => @first_id
  #    assert_response :redirect
  #    assert_redirected_to :action => 'show', :id => @first_id
  #  end
  #
  #  def test_destroy
  #    assert_nothing_raised {
  #      Category.find(@first_id)
  #    }
  #
  #    post :destroy, :id => @first_id
  #    assert_response :redirect
  #    assert_redirected_to :action => 'list'
  #
  #    assert_raise(ActiveRecord::RecordNotFound) {
  #      Category.find(@first_id)
  #    }
  #  end
end
