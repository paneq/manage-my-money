# == Schema Information
# Schema version: 20090104123107
#
# Table name: exchanges
#
#  id            :integer       not null, primary key
#  currency_a    :integer       not null
#  currency_b    :integer       not null
#  left_to_right :float         not null
#  right_to_left :float         not null
#  day           :date          not null
#  user_id       :integer       
#

class Exchange < ActiveRecord::Base
  belongs_to :left_currency,
  :class_name => "Currency",
  :foreign_key => "currency_a"
  
  belongs_to :right_currency,
  :class_name => "Currency",
  :foreign_key => "currency_b"             
  
  belongs_to  :user
  
  ##############################
  # @author: Robert Pankowecki
  def currencies
    return (left_currencies.to_a + right_currencies.to_a).uniq
  end
  
  ##############################
  # @author: Robert Pankowecki
  def before_validation 
    self.left_currency, self.right_currency, self.left_to_right, self.right_to_left = self.right_currency, self.left_currency, self.right_to_left, self.left_to_right if self.currency_a and self.currency_b and self.currency_a.id > self.currency_b.id
  end
  
  ##############################
  # @author: Robert Pankowecki
  def validate
    not_filled_fields { |error_message| errors.add(error_message) }
    errors.add("Same currencies") if same_currencies?
    errors.add("currencies order") if wrong_currencies_order?
  end
  
  ##############################
  # @author: Robert Pankowecki
  def same_currencies?
    return true if self.left_currency and self.right_currency and self.left_currency.id == self.right_currency.id
  end  
  
  ##############################
  # @author: Robert Pankowecki
  def wrong_currencies_order?
    return self.left_currency.id > self.right_currency.id
  end
  
  ##############################
  # @author: Robert Pankowecki
  # @desctiption : I block is given yields an error message for each
  #                field that is empty, otherwise returns an array of error messages
  def not_filled_fields(&proc)
    tb = []
    unless Kernel.block_given?
      block = Proc.new { |message| tb << message }
    else
      block = proc
    end
    
    block.call('Exchange from first to second') if left_to_right == nil or left_to_right <= 0
    block.call('Exchange from second to first') if right_to_left == nil or right_to_left <= 0
    
    return if Kernel.block_given?
    return tb
  end
end
