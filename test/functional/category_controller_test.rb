require File.dirname(__FILE__) + '/../test_helper'
require 'categories_controller'

# Re-raise errors caught by the controller.
class CategoryController; def rescue_action(e) raise e end; end

class CategoryControllerTest < Test::Unit::TestCase

  def setup
    @controller = CategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    save_rupert
    log_rupert
  end


  #todo poprawic by sprawdzal kiedy nie tylko domyslne kategorie ale tez dodatkowe. Ze wtedy ta dodatkowa jest w odpowiednim miejscu, nie ostatnia a wewnatrz ktorejs
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
