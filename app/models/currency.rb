# == Schema Information
# Schema version: 20090221110740
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

  named_scope :for_user_period, lambda { |user, start_day, end_day|
    { :conditions => ['((currencies.user_id = ? OR currencies.user_id IS NULL) AND transfers.user_id = ? AND transfers.day >= ? AND transfers.day <= ?)', user.id, user.id, start_day, end_day],
      :select => 'DISTINCT currencies.*',
      :joins => 'INNER JOIN transfer_items ON currencies.id = transfer_items.currency_id INNER JOIN transfers ON transfers.id = transfer_items.transfer_id'
    }
  }

  named_scope :for_user, lambda { |user|
    { :conditions => ['(currencies.user_id = ? OR currencies.user_id IS NULL)', user.id]}
  }


  named_scope :used_by, lambda { |user|
    { :conditions => ['((currencies.user_id = ? OR currencies.user_id IS NULL) AND transfers.user_id = ?)', user.id, user.id],
      :select => 'DISTINCT currencies.*',
      :joins => 'INNER JOIN transfer_items ON currencies.id = transfer_items.currency_id INNER JOIN transfers ON transfers.id = transfer_items.transfer_id'
    }
  }

  named_scope :exchanged_by, lambda { |user|
    { :conditions => ['(currencies.user_id = ? OR currencies.user_id IS NULL AND exchanges.user_id = ?)', user.id, user.id],
      :select => 'DISTINCT currencies.*',
      :joins => 'INNER JOIN exchanges ON (currencies.id = exchanges.currency_a OR currencies.id = exchanges.currency_b)'
    }
  }

  has_many  :left_exchanges,
    :class_name => "Exchange",
    :foreign_key => "currency_a"
            
  has_many  :right_exchanges,
    :class_name => "Exchange",
    :foreign_key => "currency_b"


  belongs_to  :user



  has_many :transfer_items
  has_many :goals
  before_destroy :check_for_transfer_items

  validates_presence_of :symbol, :long_symbol, :name, :long_name
  validates_uniqueness_of :long_symbol, :scope => :user_id
  validates_uniqueness_of :long_name, :scope => :user_id
  validates_length_of :long_symbol, :is => 3
  validates_format_of :long_symbol, :with => /\A[A-Z]{3}\Z/


  def validate
    # check if long name and long symbol are not take by the system currencies
    [:long_symbol, :long_name].each do |field|
      value = self.send(field)
      errors.add(field, :taken, :value => value) if self.user_id != nil && Currency.find(:first, :conditions => ["user_id IS NULL AND #{field.to_s} = ?", value])
    end
  end


  def is_system?
    return self.user_id.nil?
  end


  def exchanges
    return (left_exchanges + right_exchanges).uniq
  end


  def why_not_destroyed
    @reason
  end


  private


  def check_for_transfer_items
    if self.transfer_items(true).count > 0
      @reason = :has_transfer_items
      return false
    else
      @reason = nil
    end
  end

end
