ENV["RAILS_ENV"] = "selenium"

require 'test_helper'

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'

begin

  require 'selenium'

  class TransfersAndAutocompleteTest < Test::Unit::TestCase
    self.use_transactional_fixtures = false

    def setup
      selenium_setup
      save_currencies
      save_rupert
      create_rupert_expenses_account_structure
      log_rupert
      @selenium.set_context("Transfers Test")
    end


    def test_on_transfers_site
      save_my_transfers
      execute_with_autocomplete do
        field_id = 'transfer_description'
        field_autocomplete_id = field_id + '_auto_complete'
        @selenium.open '/transfers'
        @selenium.type_keys field_id, "Marz"

        #Nothing worked fine :-( so i just sleep to wait for autocomplete window
        Kernel.sleep 2
        # @selenium.wait_for_condition("document.getElementById('transfer_description_auto_comlete').innerHTML.length > 30", 3000)
        # @selenium.wait_for_condition("selenium.browserbot.getCurrentWindow().getElementById('transfer_description_auto_comlete').innerHTML.length > 30", 3000)
        # @selenium.wait_for_condition("this.browserbot.findElement('id=transfer_description_auto_comlete').innerHTML.length > 30", 3000)
        # @selenium.wait_for_condition("window.document.getElementById('transfer_description_auto_comlete').innerHTML.length > 30", 3000)

        # first and second transfer have the word "marzec" in description so they should be present after autcomplete shown
        @transfers[0..1].each do |t|
          #is autocomplete present
          @selenium.is_text_present t.description
        end
        
        assert_equal 2.to_s, @selenium.get_xpath_count("//div[@id='#{field_autocomplete_id}']/ul/li")  # selenium.rb -> get_number method has a really funny comment which explains why this method returns string instead of number

        # selecet the second autocomplete option by keyboard
        # i made a small reserch and from all options this one is most probably to work
        # but it does not
        # @selenium.key_press field_id, "\40"

        # other checked possibilities
        # @selenium.key_press field_autocomplete_id, "\40"
        #
        # @selenium.key_down field_id, "\40"
        # @selenium.key_up field_id, "\40"
        #
        # @selenium.key_down field_autocomplete_id, "\40"
        # @selenium.key_up field_autocomplete_id, "\40"

        # So let's click the second element by mouse
        second_complete = "//div[@id='#{field_autocomplete_id}']/ul/li[2]"
        move_and_click second_complete
        assert_equal @transfers.second.description, @selenium.get_value(field_id)

        # add 4 new transfer items on the site
        [:income, :outcome].each do |item_type|
          2.times { @selenium.click "new-#{item_type}-transfer-item" }
        end

        
      end
    end

    
    def teardown
      @selenium.stop unless $selenium
      assert_equal [], @verification_errors
      @selenium = nil
      Test::Unit::TestCase.use_transactional_fixtures = true
    end


    private


    def save_my_transfers
      @transfers = []
      
      @transfers << save_simple_transfer(
        :description =>'Wyplata za marzec',
        :day => Date.today,
        :value => 4250,
        :income => @rupert.asset,
        :outcome => @rupert.income)

      @transfers << save_simple_transfer(
        :description =>'Czynsz za marzec',
        :day => Date.yesterday,
        :value => 550,
        :income => @rent,
        :outcome => @rupert.asset)

      @transfers << save_simple_transfer(
        :description =>'Jedzenie zakupione w tesco',
        :day => Date.yesterday.yesterday,
        :value => 250,
        :income => @food,
        :outcome => @rupert.asset)
      
    end


    def execute_with_autocomplete(&proc)
      begin
        Rake::Task['ts:in'].invoke
        Rake::Task['ts:start'].invoke
        yield proc
      ensure
        Rake::Task['ts:stop'].invoke
      end
    end


    def move_and_click(locator)
      @selenium.mouse_over locator
      @selenium.click locator
    end

  end

end unless TEST_ON_STALLMAN