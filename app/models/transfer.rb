# == Schema Information
# Schema version: 20090320114536
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
  
  validates_presence_of :day
  validates_presence_of :user

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
    errors.add_to_base("Wartość elementów typu przychód i rozchód jest różna.") if different_income_outcome?
  end


  private
  
  def different_income_outcome?
    currencies_count = transfer_items.map {|ti| ti.currency_id}.uniq.size
    return different_income_outcome_one_currency? if currencies_count == 1 # Not working solution: --> if currencies.size == 1
    return different_income_outcome_many_currencies? if currencies_count > 1
    return false
  end


  def different_income_outcome_one_currency?
    return transfer_items.map{ |ti| (ti.value.nil? || !ti.errors.empty?) ? 0 : ti.value }.sum != 0.0 # Not working solution: --> ti.sum(:value)
  end


  def different_income_outcome_many_currencies?
    #TODO
  end

end
