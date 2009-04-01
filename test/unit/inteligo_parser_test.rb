require 'test_helper'
require 'hash'

class InteligoParserTest < ActiveSupport::TestCase

  def setup
    prepare_currencies
    save_rupert
    
    @rupert.categories << Category.new(:name => 'Inteligo', :description =>'inteligo main')
    @rupert.categories << Category.new(:name => 'Second Inteligo', :description =>'inteligo second one', :bank_account_number => '50102055581111100000000000')

    @rupert.save!
    @inteligo = @rupert.categories(true).find_by_name 'Inteligo'
    @inteligo2 = @rupert.categories.find_by_name 'Second Inteligo'
    assert_not_nil @inteligo
  end


  def test_parse
    # This one already in db, previously imported based on its id.
    # It does not matter that day or description is different
    t1 = save_simple_transfer(
      :day => '2222-11-27'.to_date,
      :description => 'food',
      :income => @rupert.expense,
      :outcome => @inteligo,
      :import_guid => Digest::SHA1.hexdigest('50102055581111100000000007-23'),
      :value => 68.85,
      :currency => @zloty)

    # Previously imported from file from different account that is also registered in our system.
    # Day and values must match to be found
    t2 = save_simple_transfer(
      :day => '2008-11-29'.to_date,
      :description => 'income',
      :income => @inteligo,
      :outcome => @inteligo2,
      :import_guid => Digest::SHA1.hexdigest('50102055581111100000000000-300000'),
      :value => 1032.28,
      :currency => @zloty)
      
    result = InteligoParser.new(open(RAILS_ROOT + '/test/files/inteligo.xml'), @rupert, @inteligo).parse()

    tested_result = result.find{|r| r[:transfer].transfer_items.first.value.abs == 68.85}
    assert !tested_result[:warnings].empty? #because of t1
    assert_equal [@inteligo, nil].to_set, tested_result[:transfer].transfer_items.map(&:category).to_set

    tested_result = result.find{|r| r[:transfer].transfer_items.first.value.abs == 1032.28}
    assert !tested_result[:warnings].empty? #because of t2
    assert_equal [@inteligo, @inteligo2].to_set, tested_result[:transfer].transfer_items.map(&:category).to_set #First category becuase this the one that we import transfers into. Second one becuase this bank_account_number is in db.
 
    #new currency -> CHF
    tested_result = result.find{|r| r[:transfer].transfer_items.first.value.abs == 0.04}
    assert !tested_result[:warnings].empty? #because of new currency
    new_currency = tested_result[:warnings].first.data
    assert new_currency.is_a? Currency
    assert_equal 'CHF', new_currency.long_symbol
    
  end

end