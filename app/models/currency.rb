# == Schema Information
# Schema version: 20090201170116
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

  named_scope :for_user, lambda { |user|
    { :conditions => ['(currencies.user_id = ? OR currencies.user_id IS NULL)', user.id],
      :select => 'DISTINCT currencies.*'
    }
  } do
    def in_period(start_day, end_day)
      find(:all, 
        :joins => 'INNER JOIN transfer_items ON currencies.id = transfer_items.currency_id INNER JOIN transfers ON transfers.id = transfer_items.transfer_id',
        :conditions => ['transfers.day >= ? AND transfers.day <= ?', start_day, end_day]
      )
    end
  end


  has_many  :left_exchanges,
    :class_name => "Exchange",
    :foreign_key => "currency_a"
            
  has_many  :right_exchanges,
    :class_name => "Exchange",
    :foreign_key => "currency_b"


  belongs_to  :user


  has_many :transfer_items


  validates_presence_of :symbol, :long_symbol, :name, :long_name
  validates_uniqueness_of :long_symbol, :scope => :user_id
  validates_uniqueness_of :long_name, :scope => :user_id
  validates_length_of :long_symbol, :is => 3
  validates_format_of :long_symbol, :with => /\A[A-Z]{3}\Z/

  def exchanges
    return (left_exchanges + right_exchanges).uniq
  end

end
