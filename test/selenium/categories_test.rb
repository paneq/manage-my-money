ENV["RAILS_ENV"] = "selenium"

require 'test_helper'

begin
  
  require 'selenium'

  class CategoriesTest < Test::Unit::TestCase
    self.use_transactional_fixtures = false
    
    def setup
      selenium_setup
      save_currencies
      save_rupert
      log_rupert
      @selenium.set_context("Categories Test")
    end


    def teardown
      @selenium.stop unless $selenium
      assert_equal [], @verification_errors
      @selenium = nil
      Test::Unit::TestCase.use_transactional_fixtures = true
    end


    # Tworzenie nowej kategorii
    # nr 1.2.1 main
    # test version 1.2
    def test_new_category
      @selenium.open "/categories"
      @selenium.wait_for_page_to_load "10000"

      @selenium.click "//a[@id='add-subc-#{@rupert.asset.id}']/img"
      @selenium.wait_for_page_to_load "10000"
      @selenium.type "category_name", "Portfel"
      @selenium.type "category_description", "Moj czarny portfel"
      @selenium.type "category_opening_balance", "12"
      @selenium.click "category_submit"
      @selenium.wait_for_page_to_load "10000"

      @selenium.click "//a[@id='add-subc-#{@rupert.asset.id}']/img"
      @selenium.wait_for_page_to_load "10000"
      @selenium.type "category_name", "Bank"
      @selenium.type "category_description", "Moj wspanialy bank"
      @selenium.click "category_submit"
      @selenium.wait_for_page_to_load "10000"

      children_ids = @rupert.asset.children.map{|c| c.id}
      children_divs = children_ids.map{|id| "//div[@id='category-line-#{id}']"}
      children_divs.each  do |ch_div|
        selenium_assert {assert @selenium.is_element_present ch_div}
      end

      @selenium.is_ordered children_divs.first, children_divs.second
    end


    # Tworzenie nowej kategorii
    # nr 1.2.1 alternativ a
    # test version 1.2
    def test_new_category_with_errors
      @selenium.open "/categories"
      @selenium.wait_for_page_to_load "10000"

      @selenium.click "//a[@id='add-subc-#{@rupert.asset.id}']/img"
      @selenium.wait_for_page_to_load "10000"
      # User forgotten to write category name  #  @selenium.type "category_name", ""
      @selenium.type "category_description", "Moj czarny portfel"
      @selenium.click "category_submit"
      @selenium.wait_for_page_to_load "10000"

      selenium_assert {assert @selenium.is_element_present 'errorExplanation'}

      @selenium.type "category_name", "Portfel"
      @selenium.type "category_opening_balance", "1 200P" #User has mad a mistke
      @selenium.select 'currency-select', @euro.long_name
      @selenium.click "category_submit"
      @selenium.wait_for_page_to_load "10000"

      selenium_assert {assert @selenium.is_element_present 'errorExplanation'}

      @selenium.select 'parent-select', @rupert.expense.name
      @selenium.type "category_opening_balance", "  1 200.34"
      @selenium.click "category_submit"
      @selenium.wait_for_page_to_load "10000"

      assert_not_nil @rupert.expense.children.first
      selenium_assert {assert @selenium.is_element_present "//div[@id='category-line-#{@rupert.expense.children.first.id}']"}
    end


    # Usuwanie kategorii
    # nr 1.2.3 main
    # test version 1.2
    def test_destroy_category
      create_rupert_expenses_account_structure
      save_simple_transfer(:income => @food, :value => 100.23)

      @selenium.open "/categories"
      @selenium.wait_for_page_to_load "10000"

      #Remove category with name 'food'
      @selenium.click "//a[@id='del-subc-#{@food.id}']"

      #Wait for ajax
      @selenium.wait_for_condition("selenium.getText(\"flash_notice\") != \"\"", 3000) #Not sure if written ok... Give ma a note if sth goes wrong here

      #Check for message
      flash = @selenium.get_text 'flash_notice'
      assert_match(/Usunięto/, flash)

      #check if child of destroed category was moved to the same level as destroyed category used to be on.
      @selenium.is_ordered "//div[@id='category-line-#{@house.id}']", "//div[@id='category-line-#{@healthy.id}']"

      #check saldo of parent category of destroyed category. It should contain now transfers from removed category so the saldo should be different.
      saldo = @selenium.get_text "category-saldo-#{@expense_category.id}"
      assert_match(/100\.23/, saldo)
      assert_match(Regexp.new(@zloty.symbol), saldo)
    end
    
  end
end unless TEST_ON_STALLMAN