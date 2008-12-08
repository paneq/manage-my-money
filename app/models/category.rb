# == Schema Information
# Schema version: 20081206132610
#
# Table name: categories
#
#  id          :integer       not null, primary key
#  name        :string(255)   not null
#  description :string(255)   
#  _type_      :integer       
#  category_id :integer       
#  user_id     :integer       
#

require 'hash'
require 'hash_enums'

class Category < ActiveRecord::Base
  extend HashEnums

  define_enum :category_type, [:ASSET, :INCOME, :EXPENSE, :LOAN, :BALANCE]

  acts_as_nested_set :scope=> [:user_id, :category_type_int]

  attr_accessor :opening_balance, :opening_balance_currency

  PERIODS = [ :SELECTED,
    :THIS_DAY,
    :LAST_DAY,
    :THIS_WEEK,
    :LAST_WEEK,
    :LAST_7_DAYS,
    :THIS_MONTH,
    :LAST_MONTH,
    :LAST_4_WEEKS,
    :THIS_QUARTER,
    :LAST_QUARTER,
    :LAST_3_MONTHS,
    :LAST_90_DAYS,
    :THIS_YEAR,
    :LAST_YEAR,
    :LAST_12_MONTHS
  ]
    
  belongs_to :user

  has_many :transfer_items do
    def older_than(day)
      find :all, 
        :joins => 'INNER JOIN Transfers as transfers on transfer_items.transfer_id = transfers.id',
        :conditions =>['transfers.day > ?', day]
    end
    
    def older_or_equal(day)
      find :all, 
        :joins => 'INNER JOIN Transfers as transfers on transfer_items.transfer_id = transfers.id',
        :conditions =>['transfers.day >= ?', day]
    end
    
    def between_dates(start_date, end_date)
      find :all, 
        :joins => 'INNER JOIN Transfers as transfers on transfer_items.transfer_id = transfers.id',
        :conditions =>['transfers.day > ? AND transfers.day < ?', start_date, end_date]
    end
    
    def between_or_equal_dates(start_date, end_date)
      find :all, 
        :joins => 'INNER JOIN Transfers as transfers on transfer_items.transfer_id = transfers.id',
        :conditions =>['transfers.day >= ? AND transfers.day <= ?', start_date, end_date]
    end
  end


  has_many :transfers , :through => :transfer_items, :uniq => true do
    def older_than(day)
      find :all, :conditions => ['day < ?', day]
    end
    
    def older_or_equal(day)
      find :all, :conditions => ['day <= ?', day]
    end
    
    def between_dates(start_date, end_date)
      find :all, :conditions => ['day > ? and day < ?', start_date, end_date]
    end
    
    def between_or_equal_dates(start_date, end_date)
      find :all, :conditions => ['day >= ? and day <= ?', start_date, end_date]
    end
  end


  has_many :currencies, :through => :transfer_items, :uniq => :true

  has_many :goals


  def <=>(category)
    name <=> category.name
  end


  def short_name
    name[0,15]
  end


  def parent=(element)
    @parent_to_save = element
    self.category_type_int = element.category_type_int
  end


  def after_save
    if @parent_to_save
      self.move_to_child_of(@parent_to_save)
      @parent_to_save = nil
    end
  end

#  # @description: Return a table of transfers that happend between given parameters.
#  #               Including the start_day and the end_day !
#  def transfers_between( start_day = nil , end_day = nil)
#    return transfers.between_or_equal_dates(start_day, end_day).uniq
#  end
#
#
#  def transfers_from_subcategories_between( start_day = nil , end_day = nil)
#    t = []
#    tree_with_parent().each { |c|  t+= c.transfers_between(start_day, end_day) }
#    t.uniq!
#    return t
#  end
#
#
#  # @descriptioin : Return a table o hashes that contains :saldo and :transfer related to that saldo
#  #                 The collection is sorted by day of transfer and returns also a period_saldo
#  def transfers_with_saldo_between( start_day = nil , end_day = nil )
#    transfers_with_chooseable_saldo_between( false, start_day, end_day )
#  end
#
#
#  # @descriptioin : Return a table o hashes that contains :saldo and :transfer related to that saldo
#  #                 The collection is sorted by day of transfer and returns also a period_saldo
#  def transfers_with_subcategories_saldo_between( start_day = nil , end_day = nil )
#    transfers_with_chooseable_saldo_between( true, start_day, end_day )
#  end
#
#
#
#  # @descriptioin : Return a table o hashes that contains :saldo and :transfer related to that saldo
#  #                 The collection is sorted by day of transfer and returns also a period_saldo
#  def transfers_with_chooseable_saldo_between( subcategories_saldo = false , start_day = nil , end_day = nil )
#    if start_day.nil? or end_day.nil?
#      start_day = nil
#      end_day = nil
#      start_saldo = {}
#      saldo = {}
#    else
#      start_saldo = if subcategories_saldo
#        subcategories_value_at_end_of_day( start_day - 1 )
#      else
#        value_at_end_of_day( start_day - 1 )
#      end
#      saldo = start_saldo
#    end
#    transfers = if subcategories_saldo
#      transfers_from_subcategories_between(start_day, end_day)
#    else
#      transfers_between( start_day , end_day )
#    end
#    transfers.sort! { |tr1 ,tr2| tr1.day <=> tr2.day } #this is a very important line!
#    collection = []
#    period_saldo = {}
#    transfers.each do |tr|
#      if subcategories_saldo
#        val = tr.value_by_categories( tree_with_parent() )
#      else
#        val = tr.value_by_category( self )
#      end
#      val.each_pair do |currency, value|
#        saldo = saldo.clone
#        saldo[currency] = 0 unless saldo[currency]
#        saldo[currency] += value
#        period_saldo[currency] = 0 unless period_saldo[currency]
#        period_saldo[currency] += value
#      end
#      soc = tr.single_opposite_category(self)
#      collection << { :transfer => tr, :saldo => saldo, :value => val, :destination => soc }
#    end
#    return collection, period_saldo
#  end
#
#
#  # @description: Returns the saldo of category at the end of given day
#  def value_at_end_of_day( end_day )  ## to probuje zrobic TODO
#    #poprawione zwraca hasze z walutami i odpowiadajacymi im wartosciami
#    saldo = {}
#    trans_table = transfers.older_or_equal(end_day).uniq
#    trans_table.each do |tr|
#      tr.value_by_category( self ).each_pair do |currency, value|
#        saldo[currency] = 0 unless saldo[currency]
#        saldo[currency] += value
#      end
#    end
#    return saldo
#    #TODO zoptymalizowac zeby uzywal transfer items z przedzialu dat a nie poprzez transfer.value by category
#  end
#
#
#
#  # @description: Returns the saldo of category and its child_categoris at the end of given day
#  def subcategories_value_at_end_of_day( end_day )
#    h = {}
#    tree_with_parent.each do |category|
#      category.value_at_end_of_day(end_day).each_pair do |currency, value|
#        h[currency] = 0 unless h[currency]
#        h[currency] += value
#      end
#    end
#    return h
#  end
#
#
#  def chooseable_value_at_end_of_day( end_day , with_subc = true )
#    return subcategories_value_at_end_of_day(end_day) if with_subc
#    return value_at_end_of_day(end_day)
#  end
#
#
#  def value_with_chooseable_subc(start_day = nil , end_day = nil, subc = true)
#    return value_with_subcategories( start_day, end_day) if subc
#    return value(start_day, end_day)
#  end
#
#
#  def value ( start_day = nil , end_day = nil )
#    if ( !start_day.nil? and !end_day.nil? )
#      #TODO itemy z jakiegos przedzialu czasu powinny byc u gory zdefiniowane sql a nie wybierane jak nizej selektem
#      items = transfer_items.select{ |ti| ti.transfer.day.between?(start_day, end_day)}
#    else
#      items = transfer_items
#    end
#    tb = {}
#
#    currencies.each {|c| tb[c] = 0}
#
#    items.each do |ti|
#      tb[ti.currency] += ti.value
#    end
#    return tb
#  end
  
  
  ############################
  # @author: Robert Pankowecki
#  def value_with_subcategories( start_day = nil , end_day = nil )
#    h = {}
#    tree_with_parent.collect { |cat| cat.value( start_day, end_day ) }.each do |hash|
#      hash.each_pair do |currency, value|
#        h[currency] = 0 unless h[currency]
#        h[currency] += value
#      end
#    end
#    return h
#  end
  
  
  ###########################
  # @author: Robert Pankowecki, 
  # @author: Jaroslaw Plebanski
  # @description: return hash with :only_value, :value, :sub_categories, :category
#  def info( start_day = nil , end_day = nil)
#    v = transfers_between(start_day , end_day).collect{|t| t.value_by_category(self)}.sum
#
#    h = {}
#    h[:only_value] = v
#    h[:category] = self
#    tb = []
#    child_categories.each do |c|
#      information = c.info( start_day , end_day )
#      v += information[:value]
#      tb << information
#    end
#    h[:sub_categories] = tb
#    h[:value] = v
#    return h
#  end
  
  #rupert should be ok
  #@description: return hash with :tree_value, :value, :sub_categories, :category
#  def info2( start_day = nil , end_day = nil)
#    transfers_list = transfers.between_or_equal_dates(start_day, end_day)
#    result = {:category => self}
#    result[:value] = {}
#    result[:subcategories] = []
#    transfers_list.each do |t|
#      result[:value] += t.value_by_category(self)
#    end
#    result[:tree_value] = result[:value].clone
#
#    child_categories.each do |c|
#      information = c.info(start_day, end_day)
#      result[:tree_value] += information[:tree_value]
#      result[:subcategories] << information
#    end
#    return result
#  end
  
  
  
  def before_validation
    if self.description.nil? or  self.description.empty? 
      self.description = " " #self.type.to_s + " " + self.name  
    end  
  end
  

  def is_top?
    root?
  end
    
  #======================
  #nowy kod do liczenia
  #
  
 
  def saldo_new
    money = Money.new()
    TransferItem.sum(:value, :group => 'currency_id', :conditions =>['category_id = ?', self.id]).each do |set|
      currency, value = set
      currency = Currency.find_by_id(currency)
      money.add(value, currency)
    end
    return money
  end
  
  
  def saldo_at_end_of_day(day)
    money = Money.new()
    TransferItem.sum(:value, 
      :joins => 'INNER JOIN Transfers as transfers on transfer_items.transfer_id = transfers.id', 
      :group => 'currency_id', 
      :conditions =>['category_id = ? AND transfers.day <= ?', self.id, day]).each do |set|
      currency, value = set
      currency = Currency.find_by_id(currency)
      money.add(value, currency)
    end
    return money
  end


  def current_saldo
    saldo_at_end_of_day(Date.today)
  end


  def saldo_for_period_new(start_day, end_day)
    money = Money.new()
    TransferItem.sum(:value,
      :joins => 'INNER JOIN Transfers as transfers on transfer_items.transfer_id = transfers.id',
      :group => 'currency_id',
      :conditions =>['category_id = ? AND transfers.day >= ? AND transfers.day <= ?', self.id, start_day, end_day]).each do |set|
      currency, value = set
      currency = Currency.find_by_id(currency)
      money.add(value, currency)
    end
    return money
  end


  def saldo_after_day_new(day)
    money = Money.new()
    TransferItem.sum(:value,
      :joins => 'INNER JOIN Transfers as transfers on transfer_items.transfer_id = transfers.id',
      :group => 'currency_id',
      :conditions =>['category_id = ? AND transfers.day > ?', self.id, day]).each do |set|
      currency, value = set
      currency = Currency.find_by_id(currency)
      money.add(value, currency)
    end
    return money
  end


  # Returns array of hashes{:transfer => tr, :money => Money object, :saldo => Money object}
  def transfers_with_saldo_for_period_new(start_day, end_day)    
    transfers = Transfer.find(
      :all,
      :select =>      'transfers.*, sum(transfer_items.value) as value_for_currency, transfer_items.currency_id as currency_id',
      :joins =>       'INNER JOIN transfer_items on transfer_items.transfer_id = transfers.id',
      :group =>       'transfers.id, transfer_items.currency_id',
      :conditions =>  ['transfer_items.category_id = ? AND transfers.day >= ? AND transfers.day <= ?', self.id, start_day, end_day],
      :order =>       'transfers.day, transfers.id, transfer_items.currency_id')
    
    list = []
    last_transfer = nil
    for t in transfers do
      if last_transfer == t
        list.last[:money].add(t.read_attribute('value_for_currency').to_i , Currency.find(t.read_attribute('currency_id')))
      else
        list << {:transfer => t, :money => Money.new(Currency.find(t.read_attribute('currency_id')) => t.read_attribute('value_for_currency').to_i )}
      end
      last_transfer = t
    end
    
    saldo = saldo_at_end_of_day(start_day - 1.day)
    for t in list do
      saldo.add(t[:money])
      t[:saldo] = saldo.clone
    end

    return list;
  end

  #======================
  
end
