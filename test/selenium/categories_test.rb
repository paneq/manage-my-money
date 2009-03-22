ENV["RAILS_ENV"] = "selenium"

require 'test_helper'

begin
  
  require 'selenium'

  class CategoriesTest < ActiveSupport::TestCase
    self.use_transactional_fixtures = false
    
    def setup
      selenium_setup
      prepare_currencies
      save_rupert
      log_rupert
      @selenium.set_context("Categories Test")
    end


    def teardown
      @selenium.stop unless $selenium
      @verification_errors.each do |e|
        puts
        puts e
        puts e.backtrace
        puts '---'
      end

      assert_equal [], @verification_errors

      @selenium = nil
      ActiveSupport::TestCase.use_transactional_fixtures = true
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
      children_divs = children_ids.map{|id| "//tr[@id='category-line-#{id}']"}
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
      selenium_assert {assert @selenium.is_element_present "//tr[@id='category-line-#{@rupert.expense.children.first.id}']"}
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
      @selenium.click "//a[@id='dele-subc-#{@food.id}']"

      #Wait for ajax
      @selenium.wait_for_condition("selenium.getText(\"flash_notice\") != \"\"", 3000) #Not sure if written ok... Give ma a note if sth goes wrong here

      #Check for message
      flash = @selenium.get_text 'flash_notice'
      assert_match(/Usunięto/, flash)

      #check if child of destroed category was moved to the same level as destroyed category used to be on.
      @selenium.is_ordered "//tr[@id='category-line-#{@house.id}']", "//tr[@id='category-line-#{@healthy.id}']"

      #check saldo of parent category of destroyed category. It should contain now transfers from removed category so the saldo should be different.
      saldo = @selenium.get_text "category-saldo-#{@expense_category.id}"
      assert_match(/100\.23/, saldo)
      assert_match(Regexp.new(@zloty.symbol), saldo)
    end
    
    # Edycja kategorii
    # nr 1.2.4 main
    # test version 1.2
    def test_edit_update_category
      #prepare
      create_rupert_expenses_account_structure

      # Step 1
      # Show categories
      @selenium.open "/categories"
      @selenium.wait_for_page_to_load "10000"

      # Step 2
      # Move to category 'food'
      @selenium.click "//a[@id='show-category-stats-#{@food.id}']"
      @selenium.wait_for_page_to_load "10000"

      # Step 3
      # Edit category
      @selenium.click "//a[@id='edit-cat-#{@food.id}']"

      # Step 4
      # Form appears
      @selenium.wait_for_page_to_load "10000"
      # Testing for valid options already covered by functional test:
      # CategoriesControllerTest
      # * test_edit_top_category
      # * test_edit_non_top_category


      # Step 5
      # User makes changes
      #
      # Step 5a - change name
      @selenium.type "category_name", "Jedzonko"
      # Step 5b - change description
      @selenium.type "category_description", "Moje wydatki na smaczne jedzonko"
      # Step 5c - change parent
      # move food to house, I know this is silly :-)
      @selenium.select 'parent-select', @house.name

      # Step 6
      # Submit changes
      @selenium.click "category_submit"

      # Results:
      # R1
      # -> categories
      @selenium.wait_for_page_to_load "10000"

      # R2
      # flash that was saved
      flash = @selenium.get_text 'flash_notice'
      assert_match(/Zapisano/, flash)

      # R3
      # Changed name
      @selenium.get_text "show-category-stats-#{@food.id}"

      # R4
      # Category is child of valid category
      @selenium.is_ordered "//tr[@id='category-line-#{@rent.id}']", "//tr[@id='category-line-#{@food.id}']"

      # R5
      # Changed description
      assert_not_nil @rupert.categories.find_by_name_and_description 'Jedzonko', 'Moje wydatki na smaczne jedzonko'
    end


    # Edycja kategorii
    # nr 1.2.4 alternative a
    # test version 1.2
    def test_edit_update_category_with_errors
      # Step 1
      # Show categories
      @selenium.open "/categories"
      @selenium.wait_for_page_to_load "10000"

      # Step 2
      # Move to category 'food'
      @selenium.click "//a[@id='show-category-stats-#{@rupert.expense.id}']"
      @selenium.wait_for_page_to_load "10000"

      # Step 3
      # Edit category
      @selenium.click "//a[@id='edit-cat-#{@rupert.expense.id}']"

      # Step 4
      # Form appears
      @selenium.wait_for_page_to_load "10000"

      # Step 5
      # User makes changes
      #
      # Step 5a - empty name
      @selenium.type "category_name", ""

      # Step 6
      # Submit changes
      @selenium.click "category_submit"
      @selenium.wait_for_page_to_load "10000"

      # Results :
      # R1
      selenium_assert {assert @selenium.is_element_present 'errorExplanation'}
    end

  end
end unless TEST_ON_STALLMAN