require 'hash' #confirmed

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
    @hash.default = 0;
  end


  def currencies
    return @hash.keys
  end

  
  def value(currency=nil)
    currency = @hash.keys.first if currency.nil? && @hash.size == 1
    return @hash[currency]#.to_f.round(2)
  end

  
  def currency
    if @hash.size == 1
      return @hash.first[0]
    end
    nil
  end

  #TODO should be private, IMHO jp
  def values_in_currencies
    return @hash.clone
  end

  #alias ?
  def add(money)
    self + money
  end


  def +(money)
    self.clone.add!(money)
  end


  # add(money)
  # add(value, currency)
  def add!(*args)
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
    self
  end


  # sub(money)
  # sub(value, currency)
  def -(money)
    self.clone.sub!(money)
  end


  #alias ?
  def sub(money)
    self - money
  end


  def sub!(*args)
    case args.size
    when 1
      @hash - args[0].values_in_currencies
    when 2
      @hash[args[1]] ||= 0
      @hash[args[1]] -= args[0]
    else
      raise ArgumentError, "Invalid number of arguments"
    end
    remove_zero_currencies
    self
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


  def ==(obj)
    return false unless obj.currencies.size == self.currencies.size
    for currency in self.currencies
      return false unless obj.value(currency) == self.value(currency)
    end
    return true
  end


  def clone
    return Money.new(@hash.clone)
  end


  def each
    @hash.each_pair { |key, val|  yield key, val} #val.to_f.round(2)
  end


  def positive(&block)
    positive_or_negative(:positive, block)
  end


  def negative(&block)
    positive_or_negative(:negative, block)
  end


  private


  def remove_zero_currencies
    @hash.delete_if { |currency, value|  value == 0.00}
  end


  def positive_or_negative(symbol,block = nil)
    number = (symbol == :positive ? 1 : -1)
    unless block.nil?
      @hash.each { |k,v| block.call(k,v) if (v <=> 0) == number}
    else
      hash = @hash.clone
      hash.delete_if {|k,v| (v <=> 0) != number }
      return Money.new(hash)
    end
  end

end
