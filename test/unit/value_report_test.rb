require 'test_helper'

class ValueReportTest < ActiveSupport::TestCase

  def setup
    save_jarek
  end

  test "Should create and save ValueReport" do
    r = ValueReport.new
    add_category_options @jarek, r
    r.report_view_type = :bar
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.name = "Testowy raport"
    assert r.save!
  end

  test "Should validate report_view_type" do
    r = ValueReport.new
    add_category_options @jarek, r
    r.report_view_type = :pie
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.name = "Testowy raport"
    assert !r.save
    assert r.errors.on(:report_view_type)
    assert_equal 1, r.errors.count
  end

  test "Should have many category options" do
    r = ValueReport.new
    add_category_options @jarek, r
    r.report_view_type = :bar
    r.set_period(["10.01.2009".to_date, "17.01.2009".to_date, :LAST_WEEK])
    r.name = "Testowy raport"
    r.category_report_options.each do |option|
      option.inclusion_type = :both
    end
    assert r.save
    assert_equal @jarek.categories.size, r.category_report_options.size
  end

  #TODO
  #  def test_calculate_values
  #    prepare_sample_catagory_tree_for_jarek
  #    category1 = @jarek.asset
  #    category2 = @jarek.loan
  #    test_category = @jarek.categories.find_by_name 'test'
  #
  #    result = category1.calculate_values(:category_and_subcategories, :none, 1.year.ago.to_date, 1.year.from_now.to_date)
  #
  #
  #    assert_equal 1, result.size
  #    assert_equal 2, result.first.size
  #    assert_equal :category_and_subcategories, result.first.first
  #    assert_equal Money.new, result.first.second
  #
  #
  #    result = category1.calculate_values(:category_and_subcategories, :day, '26.02.2008'.to_date, '27.02.2008'.to_date)
  #
  #    assert_equal 2, result.size
  #    assert_equal 2, result.first.size
  #    assert_equal :category_and_subcategories, result.first.first
  #    assert_equal Money.new, result.first.second
  #    assert_equal 2, result.second.size
  #    assert_equal :category_and_subcategories, result.second.first
  #    assert_equal Money.new, result.second.second
  #
  #    save_simple_transfer(:income => category1, :outcome => category2, :day => '26.02.2008'.to_date, :currency => @zloty, :value => 123, :user => @jarek)
  #
  #    result = category1.calculate_values(:category_and_subcategories, :day, '26.02.2008'.to_date, '27.02.2008'.to_date)
  #
  #    assert_equal 2, result.size
  #    assert_equal 2, result.first.size
  #    assert_equal :category_and_subcategories, result.first.first
  #    assert_equal 123, result.first.second.value(@zloty)
  #    assert_equal 2, result.second.size
  #    assert_equal :category_and_subcategories, result.second.first
  #    assert_equal Money.new, result.second.second
  #
  #
  #  end




end
