# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'hash'

class Money
  # initialize() <br />
  # initialize(currency, value) <br />
  # initialize({currency1 => value1, currency2 => value2}) <br />
  def initialize(*args)
    case args.size
    when 0
      @hash = {}
    when 1
      if args[0].class == Hash
        @hash = args[0]
      else
        raise ArgumentError.new('Invalid paramter type')
      end
    when 2
      @hash = {args[0] => args[1]}
    else
      raise ArgumentError.new('Invalid number of arguments')
    end
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
    return @hash.clone
  end


  # add(money)
  # add(value, currency)
  def add(*args)
    case args.size
    when 1
      @hash + args[0].values_in_currencies
    when 2
      @hash[args[1]] ||= 0
      @hash[args[1]] += args[0]
    else
      raise ArgumentError, "Invalid number of arguments"
    end
    remove_zero_currencies
  end
  
  def is_empty?
    return @hash.keys.size == 0
  end

  def empty?
    return is_empty?
  end

  def to_s
    return @hash.to_s
  end
  
  private
  
  def remove_zero_currencies
    @hash.delete_if { |currency, value|  value == 0.00}
  end

end
