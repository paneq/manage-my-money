ENV["RAILS_ENV"] = "selenium"

require 'test_helper'

begin
  
  require 'selenium'

  class CategoriesTest < Test::Unit::TestCase
    self.use_transactional_fixtures = false
    
    def setup
      selenium_setup
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
    
  end
end unless TEST_ON_STALLMAN