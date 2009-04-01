require 'test_helper'
#require 'hash'

class MbankParserTest < ActiveSupport::TestCase
  def setup
    prepare_currencies
    save_rupert

    @rupert.categories << Category.new(:name => 'Mbank', :description =>'mbank main')
    @rupert.categories << Category.new(:name => 'Second Mbank account', :description =>'mbank second one', :bank_account_number => '61707457942738161074662795')
    @rupert.save!

    @rupert.save!
    @mbank = @rupert.categories(true).find_by_name 'Mbank'
    @mbank2 = @rupert.categories.find_by_name 'Second Mbank account'
    assert_not_nil @mbank
    assert_not_nil @mbank2
  end


  def test_parse
    # This one already in db, previously imported based on its id.
    # It does not matter that day or description is different
    t1 = save_simple_transfer(
      :day => '2222-11-27'.to_date,
      :description => 'food',
      :income => @rupert.expense,
      :outcome => @mbank,
      :import_guid => Digest::SHA1.hexdigest(["KAPITALIZACJA ODSETEK", "1.87", "2008-06-01".to_date.to_s].join('-')),
      :value => 1.87,
      :currency => @zloty)

    # Previously imported from file from different account that is also registered in our system.
    # Day and values must match to be found
    t2 = save_simple_transfer(
      :day => '2008-10-02'.to_date,
      :description => 'income',
      :income => @mbank,
      :outcome => @mbank2,
      :import_guid => Digest::SHA1.hexdigest('Does not matter'),
      :value => -407.15,
      :currency => @zloty)

    result = nil
    open(RAILS_ROOT + '/test/files/eMAX_plus.CSV') do |f|
      result = MbankParser.new(f.read, @rupert, @mbank).parse()
    end

    tested_result = result.find{|r| r[:transfer].transfer_items.first.value.abs == 1.87}
    assert !tested_result[:warnings].empty? #because of t1
    assert_equal [@mbank, nil].to_set, tested_result[:transfer].transfer_items.map(&:category).to_set

    tested_result = result.find{|r| r[:transfer].transfer_items.first.value.abs == 407.15}
    assert !tested_result[:warnings].empty? #because of t2
    assert_equal [@mbank, @mbank2].to_set, tested_result[:transfer].transfer_items.map(&:category).to_set
    
  end


  def test_new_currency

    assert_difference("@rupert.currencies.count", 1) do
      open(RAILS_ROOT + '/test/files/eMAX_chf.CSV') do |f|
        MbankParser.new(f.read, @rupert, @mbank).parse()
      end
    end

    assert_no_difference("@rupert.currencies.count") do
      open(RAILS_ROOT + '/test/files/eMAX_chf.CSV') do |f|
        MbankParser.new(f.read, @rupert, @mbank).parse()
      end
    end

  end

end

