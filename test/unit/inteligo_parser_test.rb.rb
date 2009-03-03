require 'test_helper'
require 'hash'

class InteligoParserTest < Test::Unit::TestCase

  def setup
    save_currencies
    save_rupert
    
    @rupert.categories << Category.new(:name => 'Inteligo', :description =>'inteligo main')
    @rupert.categories << Category.new(:name => 'Second Inteligo', :description =>'inteligo second one', :bank_account_number => '50102055581111100000000000')

    @rupert.save!
    @inteligo = @rupert.categories(true).find_by_name 'Inteligo'
    @inteligo2 = @rupert.categories.find_by_name 'Second Inteligo'
    assert_not_nil @inteligo
  end


  def test_parse

    # this one already in db, previously imported based on its id.
    # it does not matter that day or description is different
    t1 = save_simple_transfer(:day => '2222-11-27'.to_date, :description => 'food', :income => @rupert.expense, :outcome => @inteligo, :import_guid => '50102055581111100000000007-23', :value => 68.85, :currency => @zloty)

    # previously imported from file from different account that is also registered in our system
    # day and values must match to be found
    t2 = save_simple_transfer(:day => '2008-11-29'.to_date, :description => 'income', :income => @inteligo, :outcome => @inteligo2, :import_guid => '50102055581111100000000000-300000', :value => 1032.28, :currency => @zloty)
      
    result = InteligoParser.parse(open(RAILS_ROOT + '/test/files/inteligo.xml'), @rupert, @inteligo)

    warnings = result.find{|r| r[:transfer].transfer_items.first.value.abs == 68.85}[:warnings]
    assert !warnings.empty? #because of t1

    warnings = result.find{|r| r[:transfer].transfer_items.first.value.abs == 1032.28}[:warnings]
    assert !warnings.empty? #because of t2 
 
    #new currency -> CHF
    warnings = result.find{|r| r[:transfer].transfer_items.first.value.abs == 0.04}[:warnings]
    assert !warnings.empty? #because of new currency
    new_currency = warnings.first.data
    assert new_currency.is_a? Currency
    assert_equal 'CHF', new_currency.long_symbol
    
  end

end