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
    lc = Category.new(:name => 'Person', :user => @rupert, :parent => @rupert.loan)
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
  

  def test_index_no_debtors
    lc = LoanCategory.new(:name => 'Person', :user => @rupert, :parent => @rupert.loan)
    lc.save!
    get :index
    assert_response :success
    assert_template 'empty_index'
    assert_select 'div#debtors_list', /Nikt.*dłużny/
  end


  def test_index
    person = LoanCategory.new(:name => 'Person', :user => @rupert, :parent => @rupert.loan, :email => 'mail@example.org')
    person.save!
    items = []
    items << save_simple_transfer(:outcome => @rupert.asset, :income => person, :currency => @zloty)
    items << save_simple_transfer(:outcome => @rupert.asset, :income => person, :currency => @euro)
    items.map!{|t| t.transfer_items.find(:first, :conditions => 'value >0')}

    bank = LoanCategory.new(:name => 'Bank', :user => @rupert, :parent => @rupert.loan)
    bank.save!

    get :index
    assert_response :success
    assert_template 'index'

    assert_select 'form[action=/debtors/remind]' do
      assert_select 'div#debtors_list' do
        assert_select 'table' do

          assert_select "tr#loan-#{person.id}" do
            assert_select "input[id=send-#{person.id}][checked=checked]"
            assert_select "td#name", Regexp.new(person.name)
            assert_select "td#email", Regexp.new(person.email)
            assert_select "td#saldo", Regexp.new(@zloty.long_symbol)
            assert_select "td#saldo", Regexp.new(@euro.long_symbol)
            assert_select "td#include" do
              assert_select "input[id=include-transfers-#{person.id}][checked=checked]"
            end
            assert_select "td#include", /Pokaż.*Ukryj/
          end

          assert_select "tr#transfer-items-list-#{person.id}" do
            assert_select "table" do
              items.each do |i|
                assert_select "tr#item-#{i.id}"
              end
            end
          end
        end #table
      end #div
      assert_select "textarea[id=text][name=text]"
      assert_select "input[type=submit][name=commit]"
    end #form

  end

end
