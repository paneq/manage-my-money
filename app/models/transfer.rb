# == Schema Information
# Schema version: 20090404090543
#
# Table name: transfers
#
#  id          :integer       not null, primary key
#  description :text          not null
#  day         :date          not null
#  user_id     :integer       not null
#  import_guid :string(255)   
#

class Transfer < ActiveRecord::Base
  
  has_many :transfer_items, :dependent => :delete_all do
    def in_category(category)
      find :all, :conditions => ['category_id = ?', category.id]
    end

    def of_type(item_type)
      conditions = {:income => 'value >= 0', :outcome => 'value <= 0'}
      find :all, :conditions => conditions[item_type]
    end
  end

  belongs_to :user

  has_many :currencies, :through => :transfer_items
  has_many :categories, :through => :transfer_items
  has_many :conversions, :dependent => :destroy
  has_many :exchanges, :through => :conversions

  default_scope :order => 'day ASC, id ASC'


  named_scope :newest, lambda { |newest_type, *args|
    transaction_amount_limit = args.shift
    case newest_type
    when :transaction_count : # 2 args required, limit and count of all
      { :limit => transaction_amount_limit, :offset => args.shift - transaction_amount_limit}
    when :week_count # 1 args required : weeks count
      start_day = (transaction_amount_limit - 1).weeks.ago.to_date.beginning_of_week
      end_day = Date.today.end_of_week
      {:conditions => ['day >= ? AND day <= ?', start_day, end_day]}
    when :this_month # 0 args required
      range = Date.calculate(:THIS_MONTH)
      {:conditions => ['day >= ? AND day <= ?', range.begin, range.end]}
    when :this_and_last_month # 0 args required
      {:conditions => ['day >= ? AND day <= ?', Date.calculate_start(:LAST_MONTH), Date.calculate_end(:THIS_MONTH)]}
    else
      raise 'Unkown type of user transaction limit'
    end
  }

  accepts_nested_attributes_for :transfer_items, :allow_destroy => true
  accepts_nested_attributes_for :conversions, :allow_destroy => true
  
  validates_presence_of :day
  validates_presence_of :user
  
  validates_user_id(
    [:transfer_items, :category],
    [:conversions, :exchange])

  validates_user_id(
    [:transfer_items, :currency],
    [:conversions, :exchange, :left_currency],
    [:conversions, :exchange, :right_currency],
    :allow_nil => true)

  define_index do
    #fields
    indexes description

    #attributes
    has user_id
    has day

    #set_property :delta => true #maybe in the future
  end

  def <=>(other_transfer)
    return day <=> other_transfer.day
  end


  protected


  def validate
    errors.add_to_base("Transfer nie posiada wymaganych conajmniej dwóch elementów.") if transfer_items.size < 2
    if different_income_outcome?
      err = "Wartość elementów typu przychód i rozchód jest różna. "
      err += @explanation if @explanation
      errors.add_to_base(err) 
      @explanation = nil
    end
  end


  private
  
  def different_income_outcome?
    currencies_count = transfer_items.map {|ti| ti.currency_id}.uniq.size
    return different_income_outcome_one_currency? if currencies_count == 1 # Not working solution: --> if currencies.size == 1
    return different_income_outcome_many_currencies? if (currencies_count > 1) && contains_required_conversions?
    return false
  end


  def different_income_outcome_one_currency?
    return valid_items.map{|ti| ti.value }.sum != 0.0 # Not working solution: --> ti.sum(:value)
  end


  def different_income_outcome_many_currencies?
    @explanation = ""
    values = []
    default = user.default_currency
    valid_conv = valid_conversions
    amount = 0

    valid_items.each_with_index do |item, number|
      
      val = if item.currency.id == default.id
        item.value
      else
        c = valid_conv.select{|conv|
          ( conv.exchange.left_currency.id == item.currency.id && conv.exchange.right_currency.id == default.id) ||
            ( conv.exchange.right_currency.id == item.currency.id && conv.exchange.left_currency.id == default.id)
        }.first
        c.exchange.exchange(item.value, default)
      end
      values << val
      amount += val
      
    end
    hash = {}
    hash[:income], hash[:outcome] = values.partition {|v| v >= 0}
    [:income, :outcome].each do |val_type|
      items = hash[val_type]
      @explanation += "#{I18n.t(val_type)}: "
      @explanation += "#{items.map{|v| " (#{v} #{default.long_symbol}) "}.join('+')} = " if items.size > 1
      @explanation += "#{items.sum()} #{default.long_symbol}. "
    end
    @explanation += "#{I18n.t(:difference)}: #{amount.abs} #{default.long_symbol}"
    return amount != 0.0
  end


  def valid_items
    transfer_items.reject{ |ti| ti.value.nil? || !ti.errors.empty? || ti.marked_for_destruction? }
  end


  def valid_conversions
    conversions.reject{ |conv| !conv.errors.empty? || conv.marked_for_destruction? }
  end


  def contains_required_conversions?
    default_id = user.default_currency.id
    currencies = transfer_items.map {|ti| ti.currency_id}.uniq
    currencies -= [default_id]

    pairs = valid_conversions.map {|conv| [conv.exchange.left_currency_id, conv.exchange.right_currency_id]}
    currencies.each do |currency_id|
      unless pairs.include?([default_id, currency_id]) || pairs.include?([currency_id, default_id])
        errors.add_to_base("Brak wymaganego kursu wymiany między użytą walutą a walutą domyślną")
        return false
      end
    end

    errors.add_to_base("Powtórzone kursy między walutami") if pairs.size != pairs.uniq.size

    return true
  end

end
