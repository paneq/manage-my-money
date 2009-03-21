ENV["RAILS_ENV"] = "selenium"

require 'test_helper'

begin
  
  require 'selenium'

  class ReportsTest < ActiveSupport::TestCase
    self.use_transactional_fixtures = false
    
    def setup
      selenium_setup
      require_memcached
      prepare_currencies
      save_rupert
      log_rupert
      @selenium.set_context("Reports Test")
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


    def test_system_reports
      make_my_transfers
      @selenium.click "raporty-menu-link"
      @selenium.wait_for_page_to_load "30000"

      #pierwszy raport systemowy
      @selenium.click "show-report-virtual-0"
      @selenium.wait_for_page_to_load "30000"
      sleep(2)
      selenium_assert {
          assert @selenium.is_text_present("Raport 'Struktura wydatków w ostatnim roku' udziału podkategorii w kategorii Wydatki w okresie")
      }
      selenium_assert {
          assert @selenium.is_text_present("W sumie:")
      }

      assert_data_table


      @selenium.click "reports-index"
      @selenium.wait_for_page_to_load "30000"

      #drugi raport systemowy
      @selenium.click "show-report-virtual-1"
      @selenium.wait_for_page_to_load "30000"
      sleep(2)
      selenium_assert {
          assert @selenium.is_text_present("Raport 'Wydatki vs. Własności vs. Przychody'")
      }
      assert_data_table

      selenium_assert {
          assert @selenium.is_text_present("Saldo")
      }

      @selenium.click "reports-index"
      @selenium.wait_for_page_to_load "30000"

      #trzeci raport systemowy
      @selenium.click "show-report-virtual-2"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("Przepływ gotówki")
      }
      selenium_assert {
          assert @selenium.is_text_present("Pieniądze do zaznaczonych kategorii przyszły z:")
      }
      selenium_assert {
          assert @selenium.is_text_present("Pieniądze z zaznaczonych kategorii wypłynęły do:")
      }
      selenium_assert {
          assert @selenium.is_text_present("W sumie:")
      }
      selenium_assert {
          assert @selenium.is_text_present("Różnica:")
      }



      copy_system_reports

      show_and_delete_user_reports

      copy_system_reports

      edit_and_show_user_reports

    end


    def test_new_share_report

      make_my_transfers
      @selenium.click "raporty-menu-link"
      @selenium.wait_for_page_to_load "30000"
      
      @selenium.click "new_report"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("Dodawanie nowego raportu")
      }
      @selenium.click "report_type_sharereport"

      selenium_assert {
          assert @selenium.is_visible("//div[@id='share_report_options']")
      }

      @selenium.click "share_report_submit"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("Raport nie został zachowany z powodu jednego błędu")
      }
      @selenium.type "share_report_name", "Mój nowy raport udziału"
      @selenium.click "//input[@id='share_report_submit' and @name='commit' and @value='Pokaż']"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("chcesz używać tego raportu w przyszłości")
      }
      @selenium.click "switch_for_graph_table_for_PLN"
      @selenium.click "switch_for_graph_table_for_PLN"
      @selenium.click "reports-index"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert !@selenium.is_text_present("Mój nowy raport udziału")
      }
    end

   



    private
    def make_my_transfers
      save_simple_transfer(:income => @rupert.asset, :outcome => @rupert.income)
      save_simple_transfer(:outcome => @rupert.asset, :income => @rupert.income, :value => 15)
      save_simple_transfer
    end

    def assert_data_table
      @selenium.click "switch_for_graph_table_for_PLN"

      selenium_assert {
          assert !@selenium.is_visible("//div[@id='graph_table_for_PLN']")
      }
      @selenium.click "switch_for_graph_table_for_PLN"

      selenium_assert {
          assert @selenium.is_visible("//div[@id='graph_table_for_PLN']")
      }
    end


    def copy_system_reports
      @selenium.click "raporty-menu-link"
      @selenium.wait_for_page_to_load "30000"


      #test kopiowania raportów
      [0,1,2].each do |num|
        @selenium.click "copy-report-#{num}"
        @selenium.wait_for_page_to_load "30000"
        selenium_assert {
            assert @selenium.is_text_present("Raport zostal pomyslnie skopiowany")
        }
      end
      @rupert.reload
    end

    def show_and_delete_user_reports
      @rupert.reports.each do |rep|

        @selenium.click "show-report-#{rep.id}"
        @selenium.wait_for_page_to_load "30000"
        @selenium.click "report-delete-#{rep.id}"
        @selenium.wait_for_page_to_load "30000"
        selenium_assert {
            assert @selenium.is_text_present("Raporty")
            assert @selenium.is_text_present("Raport zostal pomyslnie usuniety")
        }
      end

      @rupert.reload

      assert_equal 0, @rupert.reports.size
    end

    def edit_and_show_user_reports
      @rupert.reports.each do |rep|

        #edit & save
        @selenium.click "edit-report-#{rep.id}"
        @selenium.wait_for_page_to_load "30000"

        @selenium.type "#{rep.type_str.underscore}_name", "#{rep.name} 2"
        @selenium.select "report_day_#{rep.type_str}_period", "label=Ostatnie 90 dni"
        @selenium.click "#{rep.type_str.underscore}_submit"
        @selenium.wait_for_page_to_load "30000"
        selenium_assert {
            assert @selenium.is_text_present("Raport zostal pomyslnie zapisany")
        }


        #edit & show
        @selenium.click "edit-report-#{rep.id}"
        @selenium.wait_for_page_to_load "30000"

        @selenium.type "#{rep.type_str.underscore}_name", "#{rep.name} 3"
        @selenium.select "report_day_#{rep.type_str}_period", "label=Ostatnie 90 dni"
        @selenium.click "//input[@id='#{rep.type_str.underscore}_submit' and @name='commit' and @value='Pokaż']"
        @selenium.wait_for_page_to_load "30000"
        selenium_assert {
            assert @selenium.is_text_present("Twoj raport zostal dodany")
        }
        @selenium.click "reports-index"
        @selenium.wait_for_page_to_load "30000"

        #edit & save & show

        @selenium.click "edit-report-#{rep.id}"
        @selenium.wait_for_page_to_load "30000"

        @selenium.type "#{rep.type_str.underscore}_name", "#{rep.name} 4"
        @selenium.select "report_day_#{rep.type_str}_period", "label=Ostatnie 90 dni"
        @selenium.click "//input[@id='#{rep.type_str.underscore}_submit' and @name='commit' and @value='Zapisz i pokaż']"
        @selenium.wait_for_page_to_load "30000"
        selenium_assert {
            assert @selenium.is_text_present("Twoj raport zostal dodany ")
        }
        @selenium.click "reports-index"
        @selenium.wait_for_page_to_load "30000"



      end

      @rupert.reload

      assert_equal 3, @rupert.reports.size
    end




  end
end unless TEST_ON_STALLMAN