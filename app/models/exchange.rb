# == Schema Information
# Schema version: 20090306160304
#
# Table name: exchanges
#
#  id            :integer       not null, primary key
#  currency_a    :decimal(8, 4) not null
#  currency_b    :decimal(8, 4) not null
#  left_to_right :float         not null
#  right_to_left :float         not null
#  day           :date          not null
#  user_id       :integer       
#

class Exchange < ActiveRecord::Base
  belongs_to :left_currency,
    :class_name => "Currency",
    :foreign_key => "currency_a"
  
  belongs_to :right_currency,
    :class_name => "Currency",
    :foreign_key => "currency_b"
  
  belongs_to  :user

  validates_presence_of :left_to_right, :right_to_left
  validates_numericality_of :left_to_right, :right_to_left, :greater_than => 0
  validates_presence_of :left_currency, :right_currency, :day
  validates_uniqueness_of :day, :scope => [:user_id, :currency_a, :currency_b]

  #alias_method :original_save, :save

  def currencies
    return (left_currencies.to_a + right_currencies.to_a).uniq
  end
  

  def before_validation
    self.left_currency, self.right_currency, self.left_to_right, self.right_to_left = self.right_currency, self.left_currency, self.right_to_left, self.left_to_right if self.left_currency and self.right_currency and self.left_currency.id > self.right_currency.id
    #original_save
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
  
end
