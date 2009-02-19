require 'test_helper'

class LoanCategoryTest < ActiveSupport::TestCase

  def setup
    save_rupert
  end


  test "Creating Loan Categories" do
    l = LoanCategory.new(:name => 'test', :user => @rupert, :parent => @rupert.loan)
    assert_equal :LOAN, l.category_type
    assert_equal 'LoanCategory', l.type.to_s

    assert l.save    

    assert_equal :LOAN, l.category_type
    assert_not_nil LoanCategory.find_by_id(l.id)
    assert_not_nil Category.find_by_id(l.id)
    assert_equal 'LoanCategory', l.type.to_s
  end


  test "Failing to create loan subcategories" do
    (rupert.categories.top - [rupert.loan] ).each do |top_category|
      l = LoanCategory.new(:name => 'test', :user => @rupert, :parent => top_category)
      assert_not_saved_becuase_cannot_become_loan_category l

      l = Category.new(:name => 'test', :user => @rupert, :parent => top_category)
      l[:type] = 'LoanCategory'
      assert_not_saved_becuase_cannot_become_loan_category l
    end
  end


  test "Changing to Loan Category" do
    c = Category.new(:name => 'test', :user => @rupert, :parent => @rupert.loan)
    assert c.save
    assert_equal :LOAN, c.category_type
    assert_nil LoanCategory.find_by_id(c.id)

    c[:type] = LoanCategory.to_s
    assert c.save 

    c = Category.find(c.id)
    assert_equal :LOAN, c.category_type
    assert_not_nil LoanCategory.find_by_id(c.id)
  end


  test "Failing to change to loan categories" do

    rupert.categories.top.each do |top_category|
      top_category[:type] = 'LoanCategory'
      assert_not_saved_becuase_cannot_become_loan_category top_category
    end

    (rupert.categories.top - [rupert.loan] ).each do |top_category|
      category = Category.new(:name => 'test', :user => @rupert, :parent => top_category)
      category[:type] = 'LoanCategory'
      assert_not_saved_becuase_cannot_become_loan_category category
    end
    
  end


  private

  def assert_not_saved_becuase_cannot_become_loan_category(category)
    assert !category.save
    assert category.errors.on(:base)
    assert_match(/Tylko nienajwyższa kategoria typu 'Zobowiązania' może reprezentować Dłużnika lub Wierzyciela/, category.errors.on(:base).to_s)
  end
end
