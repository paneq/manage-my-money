ENV["RAILS_ENV"] = "selenium"

require 'test_helper'

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'

begin

  require 'selenium'

  class TransfersAndAutocompleteTest < ActiveSupport::TestCase
    self.use_transactional_fixtures = false

    def setup
      selenium_setup
      prepare_currencies
      save_rupert
      create_rupert_expenses_account_structure
      log_rupert
      @selenium.set_context("Transfers Test")
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


    def test_on_transfers_site
      save_my_transfers
      execute_with_autocomplete do
        field_id = "css=div[id=show-transfer-full] textarea[id^=transfer_new][id$=description]"
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
        
        assert_equal 2.to_s, @selenium.get_xpath_count("//div[@class='auto_complete'][1]/ul/li")  # selenium.rb -> get_number method has a really funny comment which explains why this method returns string instead of number

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
        second_complete = "//div[@class='auto_complete'][1]/ul/li[2]"
        move_and_click second_complete
        assert_equal @transfers.second.description, @selenium.get_value(field_id)

        @selenium.type field_id, 'Completely new transfer'

        # add 4 new transfer items on the site
        [:outcome, :income].each do |item_type|
          2.times { @selenium.click "new_#{item_type}_transfer_item" }
        end
        Kernel.sleep 0.3

        outcome_table_path = %w(div[@id='show-transfer-full'] form div[4] table[1])

        # tr w column descriptions
        test_present outcome_table_path + tbody_gen(1,1)

        # TRs with fields for adding elements
        test_usable outcome_table_path + tbody_gen(1,2)
        test_usable outcome_table_path + tbody_gen(2,1)
        test_usable outcome_table_path + tbody_gen(3,1)

        # delete two items, the first one (was at the beggining on the site) and the second (that was added few seconds ago)
        @selenium.click(path_constructor(outcome_table_path + tbody_gen(1,2) << "td[last()]/a")) # tr[2] becuase it this tbody contains one tr (with descriptions for columns) more than other elements
        @selenium.click(path_constructor(outcome_table_path + tbody_gen(2,1) << "td[last()]/a")) # previous tbody was not removed

        # no removed elements
        test_acts_as_deleted_tr outcome_table_path + tbody_gen(1,2)
        test_acts_as_deleted_tr outcome_table_path + tbody_gen(2,1)

        # yes for unremoved elements and columns descriptions
        test_usable outcome_table_path + tbody_gen(1,1) #description
        test_usable outcome_table_path + tbody_gen(3,1) #one element


        # first outcome item -> fill
        outcome_td = outcome_table_path + tbody_gen(3,1,1)
        outcome_description = outcome_td.clone << "input"
        @selenium.type_keys path_constructor(outcome_description), "Wydatki za tysiaka"

        # select category
        @selenium.select path_constructor(outcome_table_path + tbody_gen(3,1,2) << 'select'), @rupert.asset.name

        # type value
        @selenium.type_keys path_constructor(outcome_table_path + tbody_gen(3,1,3) << 'input'), "1000"

        # select currency
        @selenium.select path_constructor(outcome_table_path + tbody_gen(3,1,4) << 'select'), @zloty.long_symbol

        # first income item
        # User again made some shopping in tesco: Jedzenie zakupione w tesco
        income_table_path = %w(div[@id='show-transfer-full'] form div[5] table[1])
        income_td = income_table_path + tbody_gen(1,2,1)
        income_description = income_td.clone << "input"

        test_present income_description
        @selenium.type_keys path_constructor(income_description), @transfers.third.description[0..3] #"Jedz"

        # two autcompletes should be seen
        # one for @food and one for @rupert.asset
        Kernel.sleep 1.5
        where = path_constructor(income_td + %w(div ul li))
        assert_equal 2.to_s, @selenium.get_xpath_count(where), "Should be 2 elements like: #{where}"

        complete = nil
        (1..2).each do |nr|
          checked = path_constructor(income_td.clone + %w(div ul) << "li[#{nr}]")
          text = @selenium.get_text checked
          if text =~ Regexp.new(@food.name)
            complete = checked
            break
          end
        end
        
        assert_not_nil complete
        move_and_click complete #Click on the @food autocomplete option

        #check autocompleted description, category, value and currency
        assert_equal @transfers.third.description.to_s, @selenium.get_value(path_constructor(income_description)).to_s
        assert_equal @food.id.to_s, @selenium.get_selected_value(path_constructor(income_table_path + tbody_gen(1,2,2) << 'select')).to_s
        assert_equal @transfers.third.transfer_items.first.value.abs.to_s, @selenium.get_value(path_constructor(income_table_path + tbody_gen(1,2,3) << 'input')).to_s
        assert_equal @dolar.id.to_s, @selenium.get_selected_value(path_constructor(income_table_path + tbody_gen(1,2,4) << 'select')).to_s

        # but we do not want dollar.
        # select PLN
        @selenium.select path_constructor(income_table_path + tbody_gen(1,2,4) << 'select'), @zloty.long_symbol



        # second income item
        # user is paying for rent once again
        income_td = income_table_path + tbody_gen(2,1,1)
        income_description = income_td.clone << "input"
        test_present income_description
        @selenium.type_keys path_constructor(income_description), "marz"

        # four autcompletes should be seen
        Kernel.sleep 1.5
        where = path_constructor(income_td + %w(div ul li))
        assert_equal 4.to_s, @selenium.get_xpath_count(where)

        complete = nil
        (1..4).each do |nr|
          checked = path_constructor(income_td.clone + %w(div ul) << "li[#{nr}]")
          text = @selenium.get_text checked
          if text =~ Regexp.new(@rent.name)
            complete = checked
            break
          end
        end

        assert_not_nil complete
        move_and_click complete #Click on the @rent autocomplete option

        #check autocompleted description, category, value and currency
        assert_equal @transfers.second.description.to_s, @selenium.get_value(path_constructor(income_description)).to_s
        assert_equal @rent.id.to_s, @selenium.get_selected_value(path_constructor(income_table_path + tbody_gen(2,1,2) << 'select')).to_s
        assert_equal @transfers.second.transfer_items.first.value.abs.to_s, @selenium.get_value(path_constructor(income_table_path + tbody_gen(2,1,3) << 'input')).to_s
        assert_equal @zloty.id.to_s, @selenium.get_selected_value(path_constructor(income_table_path + tbody_gen(2,1,4) << 'select')).to_s



        # third income item
        # we do not care about autocompletion here
        #
        # type description
        income_td = income_table_path + tbody_gen(3,1,1)
        income_description = income_td.clone << "input"
        @selenium.type_keys path_constructor(income_description), "FULFILLMENT to 1000 PLN"

        # select category
        @selenium.select path_constructor(income_table_path + tbody_gen(3,1,2) << 'select'), @rupert.expense.name

        # type invalid value
        @selenium.type_keys path_constructor(income_table_path + tbody_gen(3,1,3) << 'input'), "2000" #One zero too much. We want an error to occure

        # select currency
        @selenium.select path_constructor(income_table_path + tbody_gen(3,1,4) << 'select'), @zloty.long_symbol

        #submit invalid form
        @selenium.click path_constructor( %w(div[@id='show-transfer-full'] form input[@name='commit'][@type='submit'][@value='Zapisz'] ) )

        Kernel.sleep 2
        @selenium.is_text_present "Wartość elementów typu przychód i rozchód jest różna"

        # type valid value
        @selenium.type path_constructor(income_table_path + tbody_gen(3,1,3) << 'input'), "200" #valid value

        #submit valid form
        @selenium.click path_constructor( %w(div[@id='show-transfer-full'] form input[@name='commit'][@type='submit'][@value='Zapisz'] ) )
        Kernel.sleep 2

        text = @selenium.get_text "//table[@id='transfers-table']/tbody/tr[last() - 2]/td[2]"
        assert_match(/new transfer/, text)
      end
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


    def test_present(*args)
      path_enumerator(*args) do |selector|
        assert @selenium.is_element_present(selector), "Should occure on the site: #{selector}"
        
      end
    end


    def test_usable(*args)
      selector = nil
      path_enumerator(*args) do |selector|
        assert @selenium.is_element_present(selector), "Should occure on the site: #{selector}"
      end
      assert @selenium.is_visible(selector), "Should be visible on the site: #{selector}"
    end


    def test_not_present(*args)
      selector = path_constructor(*args)
      assert !@selenium.is_element_present(selector), "Should not occure on the site: #{selector}"
    end


    def test_not_visible(*args)
      selector = path_constructor(*args)
      assert !@selenium.is_visible(selector), "Should not occure on the site: #{selector}"
    end


    def test_acts_as_deleted_tr(*args)
      test_present(*args)
      test_not_visible(*args)
      hash = args.extract_options!
      args << "td[last()]"
      args << "input[@value=1]"
      args << hash
      test_present(*args)
    end


    def path_enumerator(*args)
      raise "Code block required" unless block_given?

      defaults = {:start => '//'}
      options = args.extract_options!
      defaults.merge!(options)

      args = args.flatten
      elements = []

      args.size.times do
        elements << args.shift
        selector = defaults[:start] + elements.join('/')
        yield selector
      end
    end


    def path_constructor(*args)
      defaults = {:start => '//'}
      options = args.extract_options!
      defaults.merge!(options)

      args = args.flatten
      return defaults[:start] + args.join('/')
    end


    # tbody_gen(1) => ["tbody[1]"]
    # tbody_gen(1, 2) => ["tbody[1]", "tr[2]"]
    # tbody_gen(1, 2, 3) => ["tbody[1]", "tr[2]", "td[3]"]
    def tbody_gen(tbody, tr = nil, td = nil)
      table = ["tbody[#{tbody}]"]
      table << ["tr[#{tr}]"] if tr
      table << ["td[#{td}]"] if td
      table
    end

  end

end unless TEST_ON_STALLMAN