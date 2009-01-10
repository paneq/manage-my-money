# == Schema Information
# Schema version: 20090104123107
#
# Table name: transfers
#
#  id          :integer       not null, primary key
#  description :text          not null
#  day         :date          not null
#  user_id     :integer       not null
#

class Transfer < ActiveRecord::Base
  validates_associated :transfer_items
  
  has_many :transfer_items, :dependent => :delete_all do
    def in_category(category)
      find :all, :conditions => ['category_id = ?', category.id]
    end
  end

  belongs_to :user

  has_many :currencies, :through => :transfer_items
  
  after_update :save_transfer_items
  
  def new_transfer_items_attributes=(transfer_items_attributes)
    transfer_items_attributes.each do |attributes|
      transfer_items.build(attributes[1])
    end
  end


  def existing_transfer_items_attributes=(transfer_items_attributes)
    transfer_items.reject(&:new_record?).each do |transfer_item|
      attributes = transfer_items_attributes[transfer_item.id.to_s]
      if attributes
        transfer_item.attributes = attributes
      else
        transfer_items.delete(transfer_item)
      end
    end
  end


  def save_transfer_items
    transfer_items.each do |transfer_item|
      transfer_item.save(false)
    end
  end


  def <=>(other_transfer)
    return day <=> other_transfer.day
  end

  
  def validate
    errors.add("Total value of income and outcome are different!") if error_while_validating_io_value
  end
  

  def error_while_validating_io_value
    return !validate_io_values
  end
   
  def validate_io_values
    return (transfer_items.to_a.sum{|i| i.value} == 0)
  end
    
  def outcome_value
    sum_by_type :outcome
  end
  
  def income_value
    sum_by_type :income
  end
  
  def value
    return income_value, outcome_value
  end
  
  def categories_by_type(type)
    get_transfer_items_by_type(type).map {|t| t.category}
  end
  
  def outcome_categories
    categories_by_type :outcome
  end
  
  def income_categories
    categories_by_type :income
  end
  
  def opposite_categories(category)
    if income_categories.include?(category) 
      outcome_categories
    elsif outcome_categories.include?(category)  
      income_categories
    else
      []
    end
  end
  
  def single_opposite_category(category)
    opc = opposite_categories(category)
    if opc.size == 1 
      return opc[0]
    else  
      return nil
    end
  end
  
  def outcome_transfer_items
    get_transfer_items_by_type :outcome
  end
  
  
  def income_transfer_items
    get_transfer_items_by_type :income
  end

  def both_transfer_items
    yield(:outcome, outcome_transfer_items)
    yield(:income, income_transfer_items)
  end

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
      h[ti.currency] += ti.value
    end
    return h
  end #end of value_by_category
   
   
  private
   
  def sum_by_type (type)
    tr = get_transfer_items_by_type type
    return tr.sum { |ti| ti.value }
  end
   
  
  def get_transfer_items_by_type(type)
    return transfer_items.select { |item|  item.value >= 0} if type == :income
    return transfer_items.select { |item|  item.value < 0} if type == :outcome
    raise 'Unknown type'
  end
  
  
end
