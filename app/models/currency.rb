# == Schema Information
# Schema version: 20081110145518
#
# Table name: currencies
#
#  id          :integer       not null, primary key
#  symbol      :string(255)   not null
#  long_symbol :string(255)   not null
#  name        :string(255)   not null
#  long_name   :string(255)   not null
#  user_id     :integer       
#

class Currency < ActiveRecord::Base
  
  has_many  :left_exchanges,
            :class_name => "Exchange",
            :foreign_key => "currency_a"
            
  has_many  :right_exchanges,
            :class_name => "Exchange",
            :foreign_key => "currency_b"            
             
  belongs_to  :user
  
  has_many :transfer_items
  
  ##############################
  # @author: Robert Pankowecki
  def exchanges
    return (left_exchanges + right_exchanges).uniq
  end
  
  ##############################
  # @author: Robert Pankowecki
  def validate
    not_filled_fields { |error_message| errors.add(error_message) } 
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
    
    block.call('Symbol') if symbol.size == 0
    block.call('Long symbol') if long_symbol.size == 0
    block.call('Name') if name.size == 0
    block.call('Long name') if long_name.size == 0
    
    return if Kernel.block_given?
    return tb
  end
end
