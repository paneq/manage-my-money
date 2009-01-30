require File.dirname(__FILE__) + '/../test_helper'
require 'transfers_controller'

# Re-raise errors caught by the controller.
class TransfersController; def rescue_action(e) raise e end; end

class TransfersControllerTest < Test::Unit::TestCase


  def setup
    @controller = TransfersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    save_currencies
    save_rupert
    log_rupert
  end

  
  def test_index
    get :index
    assert_response :success
    assert_select 'div#transfer-table-div'
  end

  
  def test_index_menu
    get :index
    menu ['full', 'search'], '/transfers/search'
  end


  def test_search_responses
    day = { :day => 1.to_s, :month => 1.to_s, :year => 2020.to_s }
    ApplicationHelper::PERIODS.each do |period, description|
      xhr :post, :search,
        :transfer_day_period => period.to_s,
        :transfer_day_start  => day,
        :transfer_day_end => day
      assert_response :success
    end
  end


  def test_search
    times = [:LAST_3_MONTHS, :LAST_4_WEEKS, :LAST_7_DAYS, :THIS_DAY] #from oldest to newest
    transfers = []

    #create one transfer per one time period listed in times array
    times.each do |time|
      t = Transfer.new(:day=> Date.calculate(time).begin, :user => @rupert, :description=> time.to_s)
      t.transfer_items << TransferItem.new(:description => 'empty', :value => 100, :transfer_item_type => :income, :category => @rupert.categories.first, :currency => @rupert.visible_currencies.first)
      t.transfer_items << TransferItem.new(:description => 'empty', :value => 100, :transfer_item_type => :outcome, :category => @rupert.categories.second, :currency => @rupert.visible_currencies.first)
      t.save!
      transfers << t
    end
    
    times.each_with_index do |time, index|
      xhr :post, :search, :transfer_day_period => time.to_s
      assert_response :success
      assert_select_rjs :replace_html, 'transfer-table-div' do
        elements = times.size - index #how many transfers should be visible
        first = -elements  #negative index of first transfer that should be showed
        assert_select 'tr[id^=transfer-in-category-line]', elements #check that all elements occures
        first.upto(-1) do |index|
          transfer = transfers[index]
          assert_select "[id=transfer-in-category-#{transfer.id}]"

          [[1, :day], [2, :description]].each do |nr, method|
            #checks if elements has proper content
            assert_select "tr#transfer-in-category-line-#{transfer.id} td:nth-child(#{nr})", Regexp.new(transfer.send(method).to_s)
          end

          # checks if transfers was rendered in valid order
          assert_select "table#transfers-table tr:nth-child(#{(index + elements)*2 + 1 + 2})", Regexp.new(transfer.description) #index + elements gives you positive index (counting from 0). *2 becuase there are 2 tr per each transfer. + 1 becuase assert counts childes from 1 not from 0. +2 becuase of first 2 rows.
        end
      end
    end

    today = Date.today
    hash = { :day => today.day.to_s, :month => today.month.to_s, :year => today.year.to_s }
    xhr :post, :search,
      :transfer_day_period => 'SELECTED',
      :transfer_day_start => hash,
      :transfer_day_end => hash
    assert_response :success
    assert_select_rjs :replace_html, 'transfer-table-div' do
      assert_select 'tr[id^=transfer-in-category-line]', 1
    end
    
  end
  
end