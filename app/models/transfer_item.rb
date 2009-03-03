# == Schema Information
# Schema version: 20090301162726
#
# Table name: transfer_items
#
#  id          :integer       not null, primary key
#  description :text          not null
#  value       :decimal(8, 2) not null
#  transfer_id :integer       not null
#  category_id :integer       not null
#  currency_id :integer       default(3), not null
#  import_guid :string(255)   
#

class TransferItem < ActiveRecord::Base
	belongs_to :transfer
	belongs_to :category
  belongs_to :currency

  validates_presence_of :value
  #validates_presence_of :transfer
  validates_presence_of :category
  validates_presence_of :currency
  
  validates_numericality_of :value
  after_validation :multiply_depending_of_type

  def transfer_item_type=(tit)
    case tit.to_s.downcase
    when 'income'
      @multiply = 1
    when 'outcome'
      @multiply = -1
    else
      raise "Unknown transfer item type : #{tit}"
    end
  end

  
  def transfer_item_type
    if @multiply
      return :income if @multiply == 1
      return :outcome if @multiply == -1
      raise "Unknown situation"
    end
    return :income if  (self.value && self.value >= 0)
    return :outcome if (self.value && self.value < 0)
    raise "Unknown transfer item type"
  end


  def multiply_depending_of_type
    (self.value *= @multiply) if (@multiply && self.value)
    @multiply = nil
  end


  def error_id=(eid)
    @error_id = eid
  end


  def error_id
    return @error_id if new_record?
    return id
  end
  
end
