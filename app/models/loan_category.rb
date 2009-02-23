# == Schema Information
# Schema version: 20090221110740
#
# Table name: categories
#
#  id                :integer       not null, primary key
#  name              :string(255)   not null
#  description       :string(255)   
#  category_type_int :integer       
#  user_id           :integer       
#  parent_id         :integer       
#  lft               :integer       
#  rgt               :integer       
#  import_guid       :string(255)   
#  imported          :boolean       
#  type              :string(255)   
#  email             :string(255)   
#  bankinfo          :text          
#

class LoanCategory < Category

  def recent_unbalanced
    saldo = self.current_saldo(:default)
    twenty = self.transfers.find(:all, :limit => 20, :order => 'transfers.day DESC, transfers.id DESC', :include => :transfer_items)
    transfers = []
    number = 0
    size = twenty.size
    currencies = {}
  
    while(!saldo.empty? && number < size)
      transfer = twenty[number]
      transfers << transfer
      items = transfer.transfer_items.select{|ti| ti.category_id == self.id }
      items.each do |item|
        currencies[item.currency_id] ||= Currency.find(item.currency_id)
        saldo.sub!(item.value, currencies[item.currency_id])
      end
      number += 1
    end

    transfers.reverse!
    return transfers
  end


end
