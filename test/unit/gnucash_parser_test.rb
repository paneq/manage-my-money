require 'test_helper'

class GnucashParserTest < ActiveSupport::TestCase

  def setup
    prepare_currencies
    save_jarek
  end


  test "Parse empty file" do
    load_file 'gnucash_really_empty' do |content|
      assert_no_difference(["@jarek.categories.count", "@jarek.transfers.count", "@jarek.transfer_items.count"]) do
        GnucashParser.parse(content, @jarek)
      end
    end
  end


  test "Parse file with top categories" do
    load_file 'gnucash_empty' do |content|
      assert_no_difference(["@jarek.categories.count", "@jarek.transfers.count", "@jarek.transfer_items.count"]) do
        GnucashParser.parse(content, @jarek)
      end
    end
  end


  test "Parse file with top categories and some transfers " do
    load_file 'gnucash_empty_with_transfers' do |content|
      assert_no_difference("@jarek.categories.count") do
        assert_difference("@jarek.transfers.count", +2) do
          assert_difference("@jarek.transfer_items.count", +4) do
            GnucashParser.parse(content, @jarek)
          end
        end
      end
    end
  end


  test "Parse full file" do
    load_file 'gnucash_full' do |content|
      assert_difference("@jarek.categories.count", +14) do
        assert_difference("@jarek.transfers.count", +9) do
          assert_difference("@jarek.transfer_items.count", +22) do
            GnucashParser.parse(content, @jarek)
          end
        end
      end
    end
  end

  test "Parse full file with multi-currencies" do
    #TODO
  end

#  test "Parse file with errors" do
#    load_file 'gnucash_bad' do |content|
#      assert_no_difference(["@jarek.categories.count", "@jarek.transfers.count", "@jarek.transfer_items.count"]) do
#        GnucashParser.parse(content, @jarek)
#      end
#    end
#  end


  protected
  def load_file(name)
    open("#{RAILS_ROOT}/test/files/#{name}.xml") do |file|
      yield(file)
    end
  end


end