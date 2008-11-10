# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

class Money
  
  def initialize(hash = {})
    @hash = hash
    remove_zero_currencies
  end
  
  def currencies
    return @hash.keys
  end
  
  def value(currency)
    return @hash[currency] if currencies.include? currency
    return 0
  end
  
  def values_in_currencies
    return @hash
  end
  
  def add(value, currency)
    @hash[currency] ||= 0
    @hash[currency] += value
    remove_zero_currencies
  end
  
  def is_empty?
    return @hash.keys.size == 0
  end

  def to_s
    return @hash.to_s
  end
  
  private
  
  def remove_zero_currencies
    @hash.delete_if { |currency, value|  value == 0.00}
  end
  

end
