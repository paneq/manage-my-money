require 'test_helper'

class GnucashParserTest < ActiveSupport::TestCase

  def setup
    prepare_currencies
    save_jarek
  end


  test "Parse empty file" do
    result = nil
    load_file 'gnucash_really_empty' do |content|
      assert_no_difference(["@jarek.categories.count", "@jarek.transfers.count", "@jarek.transfer_items.count"]) do
        result = GnucashParser.parse(content, @jarek)
      end
    end
    assert_zero_in_result(result)
  end


  test "Parse file with top categories" do
    result = nil
    load_file 'gnucash_empty' do |content|
      assert_no_difference(["@jarek.categories.count", "@jarek.transfers.count", "@jarek.transfer_items.count"]) do
        result = GnucashParser.parse(content, @jarek)
      end
    end

    assert_equal 5, result[:categories][:in_file]
    assert_equal 0, result[:categories][:added]
    assert_equal 5, result[:categories][:merged]
    assert_equal 0, result[:categories][:errors].size

    assert_equal 0, result[:transfers][:in_file]
    assert_equal 0, result[:transfers][:added]
    assert_equal 0, result[:transfers][:errors].size

  end


  test "Parse file with top categories and some transfers " do
    result = nil
    load_file 'gnucash_empty_with_transfers' do |content|
      assert_no_difference("@jarek.categories.count") do
        assert_difference("@jarek.transfers.count", +2) do
          assert_difference("@jarek.transfer_items.count", +4) do
            result = GnucashParser.parse(content, @jarek)
          end
        end
      end
    end

    assert_equal 5, result[:categories][:in_file]
    assert_equal 0, result[:categories][:added]
    assert_equal 5, result[:categories][:merged]
    assert_equal 0, result[:categories][:errors].size

    assert_equal 2, result[:transfers][:in_file]
    assert_equal 2, result[:transfers][:added]
    assert_equal 0, result[:transfers][:errors].size

    transfer1 = @jarek.transfers.find_by_description 'Some food'
    assert_not_nil transfer1
    assert_equal '2009-03-31'.to_date, transfer1.day
    assert_equal 2, transfer1.transfer_items.size

    tranfer_item_11 = transfer1.transfer_items.find_by_category_id @jarek.expense.id
    assert_not_nil tranfer_item_11
    assert_equal 'food expense description', tranfer_item_11.description
    assert_equal 10.12, tranfer_item_11.value
    assert_equal @zloty, tranfer_item_11.currency

    tranfer_item_12 = transfer1.transfer_items.find_by_category_id @jarek.asset.id
    assert_not_nil tranfer_item_12
    assert_equal 'asset expense description', tranfer_item_12.description
    assert_equal(-10.12, tranfer_item_12.value)
    assert_equal @zloty, tranfer_item_12.currency

    transfer2 = @jarek.transfers.find_by_description 'Work'
    assert_not_nil transfer2
    assert_equal '2009-03-31'.to_date, transfer2.day
    assert_equal 2, transfer2.transfer_items.size

    tranfer_item_21 = transfer2.transfer_items.find_by_category_id @jarek.asset.id
    assert_not_nil tranfer_item_21
    assert_equal '', tranfer_item_21.description
    assert_equal 1000, tranfer_item_21.value
    assert_equal @zloty, tranfer_item_21.currency

    tranfer_item_22 = transfer2.transfer_items.find_by_category_id @jarek.income.id
    assert_not_nil tranfer_item_22
    assert_equal '', tranfer_item_22.description
    assert_equal(-1000, tranfer_item_22.value)
    assert_equal @zloty, tranfer_item_22.currency

  end


  test "Parse full file" do
    result = nil
    load_file 'gnucash_full' do |content|
      assert_difference("@jarek.categories.count", +14) do
        assert_difference("@jarek.transfers.count", +9) do
          assert_difference("@jarek.transfer_items.count", +22) do
            result = GnucashParser.parse(content, @jarek)
          end
        end
      end
    end

    assert_equal 17, result[:categories][:in_file]
    assert_equal 14, result[:categories][:added]
    assert_equal 3, result[:categories][:merged]
    assert_equal 0, result[:categories][:errors].size

    assert_equal 10, result[:transfers][:in_file]
    assert_equal 9, result[:transfers][:added]
    assert_equal 1, result[:transfers][:errors].size


  end



  test "Parse file with multi currencies" do
    result = nil
    load_file 'gnucash_with_currencies' do |content|
      assert_difference("@jarek.categories.count", +1) do
        assert_difference("@jarek.transfers.count", +2) do
          assert_difference("@jarek.transfer_items.count", +4) do
            result = GnucashParser.parse(content, @jarek)
          end
        end
      end
    end

    assert_equal 6, result[:categories][:in_file]
    assert_equal 1, result[:categories][:added]
    assert_equal 5, result[:categories][:merged]
    assert_equal 0, result[:categories][:errors].size

    assert_equal 3, result[:transfers][:in_file]
    assert_equal 2, result[:transfers][:added]
    assert_equal 1, result[:transfers][:errors].size

    assert_match(/transakcje wielowalutowe nie są obsługiwane/, result[:transfers][:errors].first.first)



  end

  test "Parse file with errors" do
    load_file 'gnucash_bad' do |content|
      assert_no_difference(["@jarek.categories.count", "@jarek.transfers.count", "@jarek.transfer_items.count"]) do
        assert_raise GnuCashParseError do
          GnucashParser.parse(content, @jarek)
        end
      end
    end
  end


  protected
  def load_file(name)
    open("#{RAILS_ROOT}/test/files/#{name}.xml") do |file|
      yield(file)
    end
  end

  def assert_zero_in_result(result)
    assert_equal 0, result[:categories][:in_file]
    assert_equal 0, result[:categories][:added]
    assert_equal 0, result[:categories][:merged]
    assert_equal 0, result[:categories][:errors].size

    assert_equal 0, result[:transfers][:in_file]
    assert_equal 0, result[:transfers][:added]
    assert_equal 0, result[:transfers][:errors].size

  end



end