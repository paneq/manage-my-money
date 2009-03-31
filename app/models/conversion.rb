# == Schema Information
# Schema version: 20090330164910
#
# Table name: conversions
#
#  id          :integer       not null, primary key
#  exchange_id :integer       not null
#  transfer_id :integer       not null
#  created_at  :datetime      
#  updated_at  :datetime      
#

class Conversion < ActiveRecord::Base
  belongs_to :exchange
  belongs_to :transfer

  accepts_nested_attributes_for :exchange
  validates_presence_of :exchange
  #validates_presence_of :transfer

  after_destroy :destroy_exchange_without_date


  private


  def destroy_exchange_without_date
    exchange.destroy if exchange && exchange.day.nil?
  end


end
