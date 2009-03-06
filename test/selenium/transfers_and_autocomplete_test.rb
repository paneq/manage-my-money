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
        Kernel.sleep 1.5
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
        [:outcome, :income].each do |item_type|
          2.times { @selenium.click "new-#{item_type}-transfer-item" }
        end
        Kernel.sleep 0.3

        # TRs with fields for adding elements
        assert @selenium.is_element_present "//table[@id='full-outcome-items']/tbody[1]/tr[3]"
        assert @selenium.is_element_present "//table[@id='full-outcome-items']/tbody[2]/tr[2]"

        # delete two items, the first one and the second one, that was added
        @selenium.click "//table[@id='full-outcome-items']/tbody[1]/tr[3]/td[5]/a" # tr[3] becuase it this tbody contains one tr (with descriptions for columns) more than other elements
        @selenium.click "//table[@id='full-outcome-items']/tbody[2]/tr[2]/td[5]/a" # previous tbody was not removed

        # TRs with fields for adding elements
        assert !@selenium.is_element_present("//table[@id='full-outcome-items']/tbody[1]/tr[3]")
        assert !@selenium.is_element_present("//table[@id='full-outcome-items']/tbody[2]/tr[2]")

        # first income item
        # User again made some shopping in tesco: Jedzenie zakupione w tesco
        income_description = "//table[@id='full-income-items']/tbody[1]/tr[3]/td[1]/input"
        assert @selenium.is_element_present(income_description)
        @selenium.type_keys income_description, @transfers.third.description[0..3] #"Jedz"

        # two autcompletes should be seen
        # one for @food and one for @rupert.asset
        Kernel.sleep 2
        assert_equal 2.to_s, @selenium.get_xpath_count("//table[@id='full-income-items']/tbody/tr[3]/td[1]/div/ul/li")

        complete = nil
        (1..2).each do |nr|
          checked = "//table[@id='full-income-items']/tbody[1]/tr[3]/td[1]/div/ul/li[#{nr}]"
          text = @selenium.get_text checked
          if text =~ Regexp.new(@food.name)
            complete = checked
            break
          end
        end
        
        assert_not_nil complete
        move_and_click complete #Click on the @food autocomplete option

        #check autocompleted description, category, value and currency
        assert_equal @transfers.third.description.to_s, @selenium.get_value("//table[@id='full-income-items']/tbody[1]/tr[3]/td[1]/input").to_s
        assert_equal @food.id.to_s, @selenium.get_selected_value("//table[@id='full-income-items']/tbody[1]/tr[3]/td[2]/select").to_s
        assert_equal @transfers.third.transfer_items.first.value.abs.to_s, @selenium.get_value("//table[@id='full-income-items']/tbody[1]/tr[3]/td[3]/input").to_s
        assert_equal @dolar.id.to_s, @selenium.get_selected_value("//table[@id='full-income-items']/tbody[1]/tr[3]/td[4]/select").to_s

        # but we do not want dollar.
        # select PLN
        @selenium.select "//table[@id='full-income-items']/tbody[1]/tr[3]/td[4]/select", @zloty.long_symbol



        # second income item
        # user is paying for rent once again
        income_description = "//table[@id='full-income-items']/tbody[2]/tr[2]/td[1]/input"
        assert @selenium.is_element_present(income_description)
        @selenium.type_keys income_description, "marz"

        # four autcompletes should be seen
        Kernel.sleep 1.5
        assert_equal 4.to_s, @selenium.get_xpath_count("//table[@id='full-income-items']/tbody[2]/tr[2]/td[1]/div/ul/li")

        complete = nil
        (1..4).each do |nr|
          checked = "//table[@id='full-income-items']/tbody[2]/tr[2]/td[1]/div/ul/li[#{nr}]"
          text = @selenium.get_text checked
          if text =~ Regexp.new(@rent.name)
            complete = checked
            break
          end
        end

        assert_not_nil complete
        move_and_click complete #Click on the @rent autocomplete option

        #check autocompleted description, category, value and currency
        assert_equal @transfers.second.description.to_s, @selenium.get_value("//table[@id='full-income-items']/tbody[2]/tr[2]/td[1]/input").to_s
        assert_equal @rent.id.to_s, @selenium.get_selected_value("//table[@id='full-income-items']/tbody[2]/tr[2]/td[2]/select").to_s
        assert_equal @transfers.second.transfer_items.first.value.abs.to_s, @selenium.get_value("//table[@id='full-income-items']/tbody[2]/tr[2]/td[3]/input").to_s
        assert_equal @zloty.id.to_s, @selenium.get_selected_value("//table[@id='full-income-items']/tbody[2]/tr[2]/td[4]/select").to_s



        # third income item
        # we do not care about autocompletion here
        #
        # type description
        @selenium.type_keys "//table[@id='full-income-items']/tbody[3]/tr[2]/td[1]/input", "FULFILLMENT to 1000 PLN"

        # select category
        @selenium.select "//table[@id='full-income-items']/tbody[3]/tr[2]/td[2]/select", @rupert.asset.name

        # type value
        @selenium.type_keys "//table[@id='full-income-items']/tbody[3]/tr[2]/td[3]/input", "1000"

        # select currency
        @selenium.select "//table[@id='full-income-items']/tbody[3]/tr[2]/td[4]/select", @zloty.long_symbol

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
        :outcome => @rupert.asset,
        :currency => @dolar
      )
      
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
      Kernel.sleep 0.4
    end

  end

end unless TEST_ON_STALLMAN