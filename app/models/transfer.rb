# == Schema Information
# Schema version: 8
#
# Table name: transfers
#
#  id          :integer(11)   not null, primary key
#  description :text          default(""), not null
#  day         :date          not null
#  user_id     :integer(11)   not null
#

class Transfer < ActiveRecord::Base
  has_many :transfer_items do
    def in_category(category)
      find :all, :conditions => ['category_id = ?', category.id]
    end
  end
  belongs_to :user

  has_many :currencies, :through => :transfer_items

  ############
  # @author: Mateusz Pawlik
  def destroy_with_transfer_items
    transfer_items.each { |ti| ti.destroy }
    destroy
  end

  ############
  # @author: Robert Pankowecki
  def <=>(other_transfer)
    return day <=> other_transfer.day
  end

  ############
  # @author: Robert Pankowecki
  def validate
    errors.add("Total value of income and outcome are different!") if error_while_validating_io_value
  end
  
  ############
  # @author: Robert Pankowecki
  def error_while_validating_io_value
    return !validate_io_values
  end
  
  ############
  # @author: Robert Pankowecki  
  def validate_io_values
    return outcome_value == income_value
  end
  
  ############
  # @author: Robert Pankowecki  
  def outcome_value
    sum_by_type :outcome
  end
  
  ############
  # @author: Robert Pankowecki  
  def income_value
    sum_by_type :income
  end
  
  ############
  # @author: Robert Pankowecki  
  def value
    return income_value, outcome_value
  end
  
  ############
  # @author: Jaroslaw Plebanski
  def categories_by_type(type)
    get_transfer_items_by_type(type).map {|t| t.category}
  end
  
  ############
  # @author: Jaroslaw Plebanski
  def outcome_categories
    categories_by_type :outcome
  end
  
  
  ############
  # @author: Jaroslaw Plebanski
  def income_categories
    categories_by_type :income
  end
  
  
  ############
  # @author: Jaroslaw Plebanski
  def opposite_categories(category)
    if income_categories.include?(category) 
      outcome_categories
    elsif outcome_categories.include?(category)  
      income_categories
    else
      []
    end
  end
  
  ############
  # @author: Jaroslaw Plebanski
  def single_opposite_category(category)
    opc = opposite_categories(category)
    if opc.size == 1 
      return opc[0]
    else  
      return nil
    end
  end
  
  ############
  # @author: Robert Pankowecki  
  def outcome_transfer_items
    get_transfer_items_by_type :outcome
  end
  
  
  ############
  # @author: Robert Pankowecki  
  def income_transfer_items
    get_transfer_items_by_type :income
  end

  ############
  # @author: Robert Pankowecki  
  def both_transfer_items
    yield(:outcome, outcome_transfer_items)
    yield(:income, income_transfer_items)
  end

  ############################
  # @author: Robert Pankowecki
  # @description: Calculates changes for an array of categories in very naive way.
  def value_by_categories(categories)
    h = {}
    categories.collect{ |c| value_by_category(c) }.each do |hash|
      hash.each_pair do |currency, value|
        h[currency] = 0 unless h[currency]
        h[currency] += value
      end
    end
    return h
  end
  
  ############
  # @author: Robert Pankowecki
  def value_by_category( category )
    #poprawione
    h = {}
    currencies.uniq.each {|c| h[c] = 0}
    transfer_items.in_category(category).each do |ti| 
       h[ti.currency] += if ti.gender
        ti.value
      else
        -ti.value
      end
    end
    return h
  end #end of value_by_category
   
   
  private
   
  ############
  # @author: Robert Pankowecki   
  def sum_by_type (type)
    tr = get_transfer_items_by_type type
    return tr.sum { |ti| ti.value }
  end
   
   
  ############
  # @author: Robert Pankowecki   
  def get_transfer_items_by_type (type)
    transfers = []
    gender = true
    gender = false if type == :outcome
    transfer_items.each do |ti|
      transfers << ti if ti.gender == gender
    end
    transfers
  end
  
  
end
