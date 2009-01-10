# == Schema Information
# Schema version: 20090104123107
#
# Table name: transfer_items
#
#  id          :integer       not null, primary key
#  description :text          not null
#  value       :integer       not null
#  transfer_id :integer       not null
#  category_id :integer       not null
#  currency_id :integer       default(3), not null
#

class TransferItem < ActiveRecord::Base
	belongs_to :transfer
	belongs_to :category
  belongs_to :currency

  validates_numericality_of :value
  before_validation_on_create :multiply_depending_of_type


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
    return :income if (!!@multiply && @multiply == 1) || (self.value &&self.value >= 0)
    return :outcome if (!!@multiply && @multiply == -1) || (self.value && self.value < 0)
    raise "Unknown transfer item type"
  end


  def multiply_depending_of_type
    (self.value *= @multiply) if @multiply
    @multiply = nil
  end


end
