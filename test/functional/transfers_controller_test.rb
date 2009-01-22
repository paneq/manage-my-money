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
    list = [:LAST_3_MONTHS, :LAST_4_WEEKS, :LAST_7_DAYS, :THIS_DAY] #from oldest to newest
    transfers = []
    list.each do |time|
      t = Transfer.new(:day=> Date.calculate(time).begin, :user => @rupert, :description=> 'empty')
      t.transfer_items << TransferItem.new(:description => 'empty', :value => 100, :transfer_item_type => :income, :category => @rupert.categories.first, :currency => @rupert.visible_currencies.first)
      t.transfer_items << TransferItem.new(:description => 'empty', :value => 100, :transfer_item_type => :outcome, :category => @rupert.categories.second, :currency => @rupert.visible_currencies.first)
      t.save!
      transfers << t
    end
    
    list.each_with_index do |time, index|
      xhr :post, :search, :transfer_day_period => time.to_s
      assert_response :success
      assert_select_rjs :replace_html, 'transfer-table-div' do
        elements = list.size - index
        first = -elements
        assert_select 'tr[id^=transfer-in-category-line]', elements
        first.upto(-1) do |index|
          transfer = transfers[index]
          assert_select "[id=transfer-in-category-#{transfer.id}]"
          [[1, :day], [2, :description]].each do |nr, method|
            assert_select "tr#transfer-in-category-line-#{transfer.id} td:nth-child(#{nr})", Regexp.new(transfer.send(method).to_s)
          end
        end
      end
    end

    #TODO: Przetestowac selected
    #TODO: Ustawic order w zwracanej kolejnosci dla transfer tabla
    #TODO: Sprawdzic czy order prawidlowy w testach przy odrysowywaniu transfer table
    
  end
  
end