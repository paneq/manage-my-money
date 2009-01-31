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
    assert_menu ['full', 'search'], '/transfers/search'
  end


  def test_index_transaction_count
    @rupert.update_attributes! :transaction_amount_limit_type => :transaction_count, :transaction_amount_limit_value => 2

    # test when no transfer
    get :index
    assert_transfer_table [], :way => :get

    #two transfer and limit is 2
    transfers = []
    2.times {|time| transfers << save_simple_transfer(:description => time.to_s) }
    get :index
    assert_transfer_table transfers, :way => :get

    #three trnasfers and limit is 3
    transfers << save_simple_transfer(:description => '3')
    get :index
    assert_transfer_table [transfers.second, transfers.third], :way => :get
  end


  def test_index_week_count
    #only current week
    @rupert.update_attributes! :transaction_amount_limit_type => :week_count, :transaction_amount_limit_value => 1
    transfers = []

    #create a transfer for every day of current week
    today = Date.today
    (today.beginning_of_week..today.end_of_week).each do |day|
      transfers << save_simple_transfer(:description => day.to_s, :day => day)
    end

    #one transfer in the future and one in the past
    save_simple_transfer(:description => 'future', :day => today.end_of_week.tomorrow)
    long_past = save_simple_transfer(:description => 'past', :day => today.beginning_of_week.yesterday.beginning_of_week)
    close_past = save_simple_transfer(:description => 'past', :day => today.beginning_of_week.yesterday)

    #check for transfers from only this week
    get :index
    assert_transfer_table transfers, :way => :get

    @rupert.update_attributes! :transaction_amount_limit_value => 2
    #little hack, otherwise controller remebers currently logged user and his settings are not readed again
    @controller = TransfersController.new
    get :index
    assert_transfer_table [long_past, close_past] + transfers, :way => :get
  end


  def test_index_actual_month
    @rupert.update_attribute 'transaction_amount_limit_type', :actual_month
    transfers = []
    today = Date.today
    (today.beginning_of_month..today.end_of_month).each do |day|
      transfers << save_simple_transfer(:description => day.to_s, :day => day) if (day.day / 4 == 0)
    end

    save_simple_transfer(:description => 'future', :day => today.end_of_month.tomorrow)
    save_simple_transfer(:description => 'past', :day => today.beginning_of_month.yesterday)

    get :index
    assert_transfer_table transfers, :way => :get
  end


  def test_index_actual_and_last_month
    @rupert.update_attribute 'transaction_amount_limit_type', :actual_and_last_month
    transfers = []
    today = Date.today
    last_month = Date.today.last_month
    (last_month.beginning_of_month..today.end_of_month).each do |day|
      transfers << save_simple_transfer(:description => day.to_s, :day => day) if (day.day / 5 == 0)
    end

    save_simple_transfer(:description => 'future', :day => today.end_of_month.tomorrow)
    save_simple_transfer(:description => 'past', :day => last_month.beginning_of_month.yesterday)

    get :index
    assert_transfer_table transfers, :way => :get
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
      assert_transfer_table transfers[index..transfers.size]
    end

    today = Date.today
    hash = { :day => today.day.to_s, :month => today.month.to_s, :year => today.year.to_s }
    xhr :post, :search,
      :transfer_day_period => 'SELECTED',
      :transfer_day_start => hash,
      :transfer_day_end => hash
    assert_response :success
    assert_transfer_table [transfers.last]
  end


  def test_quick_transfer
    today = Date.today
    transfers = []
    @asset = @rupert.categories.top_of_type(:ASSET)
    save_simple_transfer(:description => 'future', :day => today.end_of_month.tomorrow, :income => @asset)
    transfers << save_simple_transfer(:description => 'this_month', :day => today, :income => @asset)
    save_simple_transfer(:description => 'past', :day => today.beginning_of_month.yesterday, :income => @asset)

    xhr :post, :quick_transfer,
      :current_category => @asset.id.to_s,
      :data => {
      'description' => 'test',
      'day(1i)' => today.year.to_s,
      'day(2i)' => today.month.to_s,
      'day(3i)' => today.day.to_s,
      'category_id' => @asset.id.to_s,
      'currency_id' => @rupert.default_currency.id.to_s,
      'value' => '123.45',
      'from_category_id' => @rupert.categories.top_of_type(:INCOME).id.to_s,
    }
    assert_response :success
    transfers << @rupert.transfers(true).find_by_description('test')
    assert_transfer_table transfers
  end


  private

  #checks if transfer table contains all transfers given as first paramters and if they are in proper order
  def assert_transfer_table(transfers, options = {:way => :xhr})
    method = options[:way] == :xhr ? 'assert_select_rjs' : 'assert_select'
    params = options[:way] == :xhr ? [:replace_html, 'transfer-table-div'] : 'div#transfer-table-div'

    send(method, *params) do

      assert_select 'tr[id^=transfer-in-category-line]', transfers.size #check that all elements occures

      transfers.each_with_index do |transfer, index|
        assert_select "[id=transfer-in-category-#{transfer.id}]"

        [[1, :day], [2, :description]].each do |nr, method|
          #checks if elements has proper content
          assert_select "tr#transfer-in-category-line-#{transfer.id} td:nth-child(#{nr})", Regexp.new(transfer.send(method).to_s)
        end

        # checks if transfers was rendered in valid order by checking its description
        assert_select "table#transfers-table tr:nth-child(#{index*2 + 1 + 2})", Regexp.new(transfer.description) # index*2 becuase there are 2 tr per each transfer. + 1 becuase assert counts childes from 1 not from 0. +2 becuase of first 2 rows.
      end
    end

  end


  
end