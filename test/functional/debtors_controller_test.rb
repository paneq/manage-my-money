require 'test_helper'

class DebtorsControllerTest < ActionController::TestCase

  def setup
    save_currencies
    save_rupert
    log_rupert
  end

  def test_index_no_loan_subcategories
    get :index
    assert_response :success
    assert_template 'empty_index'
    assert_select 'div#debtors_list', /lista.*jest.*pusta/
    assert_select 'div#debtors_list', /Dodaj nowe osoby/
  end


  def test_index_subcategory_is_not_LoanCategory
    lc = Category.new(:name => 'Osoba', :type => 'LoanCategory', :user => @rupert, :parent => @rupert.loan)
    lc.save!
    get :index
    assert_response :success
    assert_template 'empty_index'
    assert_select 'div#debtors_list', /lista.*jest.*pusta/
    assert_select 'div#debtors_list', /zaznacz.*odpowiednią.*opcję/
    assert_select 'ul#possible' do
      assert_select "li#category_#{lc.id}", Regexp.new(lc.name)
      assert_select "li#category_#{lc.id}", /Edytuj/
      assert_select "li#category_#{lc.id}", /Pokaż/
    end
  end
  

  def test_index

  end


end
