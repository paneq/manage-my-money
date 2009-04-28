# == Schema Information
# Schema version: 20090414090944
#
# Table name: exchanges
#
#  id                :integer       not null, primary key
#  left_currency_id  :integer       not null
#  right_currency_id :integer       not null
#  left_to_right     :decimal(8, 4) not null
#  right_to_left     :decimal(8, 4) not null
#  day               :date          
#  user_id           :integer       
#

class Exchange < ActiveRecord::Base
  attr_protected :user_id
  
  belongs_to :left_currency,
    :class_name => "Currency",
    :foreign_key => "left_currency_id"
  
  belongs_to :right_currency,
    :class_name => "Currency",
    :foreign_key => "right_currency_id"
  
  belongs_to  :user

  has_many :conversions
  has_many :transfers, :through => :conversions

  named_scope :for_currencies, lambda { |a,b|
    a,b = Exchange.switch(a,b)
    {:conditions => ['left_currency_id = ? AND right_currency_id = ?', a.id, b.id]}
  }

  named_scope :newest, :order => 'day DESC', :limit => 1, :conditions => ['day <= ?', Date.today]
  named_scope :daily, :conditions => ['day IS NOT NULL']


  validates_presence_of :left_to_right, :right_to_left
  validates_numericality_of :left_to_right, :right_to_left, :greater_than => 0
  validates_presence_of :left_currency, :right_currency

  validates_presence_of :day, :if => :day_required
  attr_accessor :day_required

  validates_uniqueness_of :day, :scope => [:user_id, :left_currency_id, :right_currency_id], :allow_nil => true, :allow_blank => true

  validates_user_id :left_currency, :right_currency, :allow_nil => true
  
  def currencies
    return (left_currencies.to_a + right_currencies.to_a).uniq
  end
  

  def before_validation
    self.left_currency, self.right_currency, self.left_to_right, self.right_to_left = self.right_currency, self.left_currency, self.right_to_left, self.left_to_right if self.left_currency and self.right_currency and self.left_currency.id > self.right_currency.id
  end
  

  def validate
    errors.add_to_base(:wrong_order) if wrong_currencies_order?
    errors.add(:right_currency, :same_as_left) if same_currencies?
  end
  

  def same_currencies?
    return true if self.left_currency.is_a?(Currency) and self.right_currency.is_a?(Currency) and self.left_currency.id == self.right_currency.id
    return false
  end  
  

  def wrong_currencies_order?
    return self.left_currency.is_a?(Currency) && self.right_currency.is_a?(Currency) && self.left_currency.id > self.right_currency.id
  end

  
  def self.switch(a,b)
    a,b = b,a if a.id > b.id
    return a,b
  end


  def exchange(amount, currency)
    if left_currency == currency
      return (amount*right_to_left).to_f.round(2)
    end

    if right_currency == currency
      return (amount*left_to_right).to_f.round(2)
    end

    raise 'Wrong currency given'
  end
end
