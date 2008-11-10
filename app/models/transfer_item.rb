# == Schema Information
# Schema version: 20081110145518
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
end
