# == Schema Information
# Schema version: 8
#
# Table name: transfer_items
#
#  id          :integer(11)   not null, primary key
#  description :text          default(""), not null
#  gender      :boolean(1)    not null
#  value       :integer(11)   not null
#  transfer_id :integer(11)   not null
#  category_id :integer(11)   not null
#

class TransferItem < ActiveRecord::Base
	belongs_to :transfer
	belongs_to :category
  belongs_to :currency
end
