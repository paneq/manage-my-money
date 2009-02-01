# == Schema Information
# Schema version: 20090104123107
#
# Table name: categories
#
#  id                :integer       not null, primary key
#  name              :string(255)   not null
#  description       :string(255)   
#  category_type_int :integer       
#  user_id           :integer       
#  parent_id         :integer       
#  lft               :integer       
#  rgt               :integer       
#

   

require 'hash'
require 'hash_enums'

class Category < ActiveRecord::Base
  extend HashEnums

  define_enum :category_type, [:ASSET, :INCOME, :EXPENSE, :LOAN, :BALANCE]

  acts_as_nested_set :scope=> [:user_id, :category_type_int], :dependent => :destroy

  attr_accessor :opening_balance, :opening_balance_currency

  attr_accessor :parent_guid #for importing

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

  has_many :category_report_options, :foreign_key => :category_id
  has_many :multiple_category_reports, :through => :category_report_options

  validates_presence_of :name


  def <=>(category)
    name <=> category.name
  end


  #Zwraca nazwę kategorii wraz ze ścieżka utworzoną ze wszystkich jej nadkategorii
  #np dla kategorii Owoce -> Wydatki:Jedzenie:Owoce
  def name_with_path
    path = self_and_ancestors.inject('') { |sum, cat| sum += cat.name + ':'}
    path[0,path.size-1]
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
      @parent_to_save = :default
    end
  end

  alias_method :original_destroy, :destroy

  def destroy
    #this could not be done with before_destroy because all children are destroyed first and then before_destroy is exectued
    # in other words before_destroy is exectued before destroying object but after destroying child objects...
    # Look: :dependent => :destroy

    throw :indestructible if is_top? #cannot be destroyed but can be deleted

    children.to_a.each do |c|
      c.parent = self.parent
      c.save!
    end 

    TransferItem.update_all("category_id = #{self.parent.id}", "category_id = #{self.id}")

    # Moving children makes SQL queries that updates current object lft and rgt fields.
    # Becuase of that we need to update it calling reload_nested_set so valid fields are stored
    # and another sql queries are exectued with valid values -> queries that destroy children
    reload_nested_set
    original_destroy

  end
  
  def before_validation
    if self.description.nil? or self.description.empty?
      self.description = " " #self.type.to_s + " " + self.name  
    end  
  end
  

  def is_top?
    root?
  end
    
  #======================
  #nowy kod do liczenia
  #
  
 
  def saldo_new(algorithm=:default, with_subcategories = false)
    universal_saldo(algorithm, with_subcategories)
  end

  
  def saldo_at_end_of_day(day, algorithm=:default, with_subcategories = false)
    universal_saldo(algorithm, with_subcategories, 't.day <= ?', day)
  end


  def saldo_for_period_new(start_day, end_day, algorithm=:default, with_subcategories = false)
    universal_saldo(algorithm, with_subcategories, 't.day >= ? AND t.day <= ?', start_day, end_day)
  end

  def saldo_for_period_with_subcategories(start_day, end_day, algorithm=:default)
    saldo_for_period_new(start_day, end_day, algorithm, true)
  end



  def saldo_after_day_new(day, algorithm=:default, with_subcategories = false)
    universal_saldo(algorithm, with_subcategories, 't.day > ?', day)
  end


  def current_saldo(algorithm=:default)
    saldo_at_end_of_day(Date.today, algorithm)
  end


  # Returns array of hashes{:transfer => tr, :money => Money object, :saldo => Money object}
  def transfers_with_saldo_for_period_new(start_day, end_day, with_subcategories = false)
    categories = get_categories_id(with_subcategories)
    transfers = Transfer.find(
      :all,
      :select =>      'transfers.*, sum(transfer_items.value) as value_for_currency, transfer_items.currency_id as currency_id',
      :joins =>       'INNER JOIN transfer_items on transfer_items.transfer_id = transfers.id',
      :group =>       'transfers.id, transfer_items.currency_id',
      :conditions =>  ['transfer_items.category_id IN (?) AND transfers.day >= ? AND transfers.day <= ?', categories, start_day, end_day],
      :order =>       'transfers.day, transfers.id, transfer_items.currency_id')
    
    list = []
    last_transfer = :default
    for t in transfers do
      if last_transfer == t
        list.last[:money].add(t.read_attribute('value_for_currency').to_i , Currency.find(t.read_attribute('currency_id')))
      else
        list << {:transfer => t, :money => Money.new(Currency.find(t.read_attribute('currency_id')) => t.read_attribute('value_for_currency').to_i )}
      end
      last_transfer = t
    end
    
    saldo = saldo_at_end_of_day(start_day - 1.day, :show_all_currencies, with_subcategories)
    for t in list do
      saldo.add(t[:money])
      t[:saldo] = saldo.clone
    end

    return list;
  end


  #TODO
  # Oblicza udzial wartosci podkategorii w kategorii
  # 
  # Parametry:
  #  share_type to jedno z [:percentage, :value]
  #  max_categories_count liczba podkategorii do uwzglednienia, pozostale podkategorie znajduja sie w wartosci 'pozostale'
  #  depth stopien zaglebienia w podkategorie w obliczeniach
  #  period_start, period_end zakres czasowy
  #
  # Wyjscie:
  #  tablica tablic postaci:
  #  [[wartosc1,nazwa1],[wartosc2,nazwa2]]
  #  sortowanie od najwiekszej wartosci
  def calculate_share_values(max_categories_count, depth, period_start, period_end, share_type)
    [[9,'Nazwa1'],[7,'Nazwa2'],[2,'Nazwa3'],[1,'Nazwa4'],[5,'Pozostale']]
  end
  

  #TODO
  #TODO co z walutami?
  # Podaje saldo/salda kategorii w podanym czasie
  #
  # Parametry:
  #  inclusion_type to jedno z [:category_only, :category_and_subcategories, :both]
  #  period_division to jedno z [:day, :week, :none...] podzial podanego zakresu czasu na podokresy
  #  period_start, period_end zakres czasowy
  #
  # Wyjscie:
  #  hash z maksymalnie dwoma tablicami wartosci postaci:
  #  {:category_only => [money,money,money],
  #  :category_and_subcategories => [money,money,money]}
  #  w szczegolnym przypadku tablica moze byc jednoelementowa, np gdy period_division == :none
  #  sortowanie od najstarszej wartosci
  #
  def calculate_values(inclusion_type, period_division, period_start, period_end)
    result = []
    dates = Date.split_period(period_division, period_start, period_end)
    
#    result[:category_only] = []
    dates.each do |date_range|
      result << [:category_only, saldo_for_period_new(date_range[0], date_range[1])] if inclusion_type == :category_only || inclusion_type == :both
      result << [:category_and_subcategories, saldo_for_period_with_subcategories(date_range[0], date_range[1])] if inclusion_type == :category_and_subcategories || inclusion_type == :both
    end

    result
  end


  #TODO
  # Uwaga: powinno sie znalezc w jakims bardziej uniwersalnym miejscu (module/klasie)
  # Podaje etykiety dla wartosci generowanych przez metode calculate_values
  #
  # Parametry:
  #  takie jak w calculate_values
  #
  # Wyjście:
  #  tablica wartosci postaci:
  #  ['tydzien1','tydzien2','tydzien3']
  #  ['Styczen','Luty','Marzec']
  #  ['Poniedzialek', 'Wtorek']
  #  ['2007','2008']
  #  [''] dla period_division == :none
  #  sortowanie od etykiety opisujacej najstarsza wartosc
  def self.get_values_labels(period_division, period_start, period_end)
    dates = Date.split_period(period_division, period_start, period_end)
    result = []
    case period_division
    when :day then
      dates.each do |range|
        result << "#{range[0].to_s}"
      end
    when :week then
      dates.each do |range|
        result << "#{range[0].to_s} do #{range[1].to_s}"
      end
    when :month then
      dates.each do |range|
        result << I18n.l(range[0], :format => '%Y %b ')
      end
    when :quarter then
      dates.each do |range|
        result << "#{quarter_number(range[0])} kwartał #{range[0].strftime('%Y')}"
      end
    when :year then
      dates.each do |range|
        result << range[0].strftime('%Y')
      end
    when :none then
      dates.each do |range|
        result << "#{range[0].to_s} do #{range[1].to_s}"
      end
    end
    result
  end

  def self.quarter_number(date)
    case (date.at_beginning_of_quarter.month)
    when 1 then "I"
    when 4 then "II"
    when 7 then "III"
    when 10 then "IV"
    end
  end


  #
  #
  # Wyjście:
  # hash z dwoma kluczami :in oraz :out
  # z których każdy zawiera tabele...
  # przykład
  # {
  # :in => [
  #         {
  #          :category => Category,
  #          :values => Money
  #         },
  #         {
  #          :category => category,
  #          :values => Money
  #         }
  # ],
  # :out => [] }

  def self.calculate_flow_values(categories, period_start, period_end)
    categories.collect! { |cat| cat.id }
    flow_categories = Category.find(
      :all,
      :select =>      'categories.*,
                       ti2.value >=0 as income,
                       ti2.currency_id,
                       sum(abs(ti2.value)) as sum_value',
      :joins =>       'INNER JOIN transfers t on categories.id = ti2.category_id
                       INNER JOIN transfer_items ti on ti.transfer_id = t.id
                       INNER JOIN transfer_items ti2 on ti2.transfer_id = t.id',
      :group =>       'ti2.category_id,
                       ti2.currency_id,
                       ti2.value >= 0',
      :conditions =>  ['ti.category_id in (?)
                        and ti2.category_id not in (?)
                        AND t.day >= ?
                        AND t.day <= ?',
                        categories, categories, period_start, period_end],
      :order =>       'categories.category_type_int, categories.lft')

    #TODO: cumulate Money walues for one category

    flow_categories.collect! do |cat|
      {
        :category => cat,
        :values => Money.new( Currency.find(cat.read_attribute('currency_id') ), cat.read_attribute('sum_value').to_f )
      }
    end

    cash_in, cash_out = flow_categories.partition { |cat_hash| cat_hash[:category].read_attribute('income') == '0'}

    {:out => cash_out, :in => cash_in}
  end

  #======================
  private



  def universal_saldo(algorithm = :default, with_subcategories = false, additional_condition="", *params)
    algorithm = algorithm(algorithm, with_subcategories)
    unless additional_condition.blank?
      algorithm[:conditions].first << " AND #{additional_condition}"
      algorithm[:conditions] += params
    end

    money = Money.new()

    TransferItem.sum(:value, algorithm).each do |set|
      if set.class == Array
        # group by currency
        currency, value = set
        currency = Currency.find_by_id(currency)
        money.add(value, currency)
      else
        # calculated to one value in default currency
        money.add(set.to_f, Currency.find_by_id(self.user.default_currency))
      end
    end
    return money

  end


  def algorithm(algorithm, with_subcategories = false)
    return algorithm(self.user.multi_currency_balance_calculating_algorithm, with_subcategories) if algorithm == :default


    categories_to_sum = get_categories_id(with_subcategories)

    return case algorithm
    when :calculate_with_exchanges_closest_to_transaction
      currency = self.user.default_currency
      {
        :select => "
        CASE
        WHEN ti.currency_id = #{currency.id} THEN ti.value
        WHEN ex.currency_a = #{currency.id} THEN ti.value*ex.right_to_left
        WHEN ex.currency_a != #{currency.id} THEN ti.value*ex.left_to_right
        END
        ",

        :from => 'transfer_items as ti',

        :joins =>"
        JOIN transfers AS t ON (ti.transfer_id = t.id)
        LEFT JOIN exchanges as ex ON
          (
          ti.currency_id != #{currency.id} AND ex.Id IN
            (
              SELECT Id FROM exchanges as e WHERE
                (
                abs( julianday(t.day) - julianday(e.day) ) =
                  (
                  SELECT min( abs( julianday(t.day) - julianday(e2.day) ) ) FROM exchanges as e2 WHERE
                    (
                    (e2.user_id = #{self.user.id} ) AND
                    (e2.currency_a = #{currency.id} AND e2.currency_b = ti.currency_id) OR (e2.currency_a = ti.currency_id AND e2.currency_b = #{currency.id})
                    )
                  )
                AND
                  (
                  (e.currency_a = #{currency.id} AND e.currency_b = ti.currency_id) OR (e.currency_a = ti.currency_id AND e.currency_b = #{currency.id})
                  )
                AND
                  (
                  e.user_id = #{self.user.id}
                  )
                )
              ORDER BY e.day ASC LIMIT 1
            )
          )
        ",
        :conditions => ['t.user_id = ? AND ti.category_id IN (?)', self.user.id, categories_to_sum]
      }
    when :calculate_with_newest_exchanges
      currency = self.user.default_currency
      {
        :select => "
        CASE
        WHEN ti.currency_id = #{currency.id} THEN ti.value
        WHEN ex.currency_a = #{currency.id} THEN ti.value*ex.right_to_left
        WHEN ex.currency_a != #{currency.id} THEN ti.value*ex.left_to_right
        END
        ",

        :from => 'transfer_items as ti',

        :joins =>"
        JOIN transfers AS t ON (ti.transfer_id = t.id)
        LEFT JOIN exchanges as ex ON
          (
          ti.currency_id != #{currency.id} AND ex.Id IN
            (
              SELECT Id FROM Exchanges as e WHERE
                (
                abs( julianday('now', 'start of day') - julianday(e.day) ) =
                  (
                  SELECT min( abs( julianday('now', 'start of day') - julianday(e2.day) ) ) FROM Exchanges as e2 WHERE
                    (
                    (e2.user_id = #{self.user.id} ) AND
                    ((e2.currency_a = #{currency.id} AND e2.currency_b = ti.currency_id) OR (e2.currency_a = ti.currency_id AND e2.currency_b = #{currency.id}))
                    )
                  )
                AND
                  (
                  (e.currency_a = #{currency.id} AND e.currency_b = ti.currency_id) OR (e.currency_a = ti.currency_id AND e.currency_b = #{currency.id})
                  )
                AND
                  (
                  e.user_id = #{self.user.id}
                  )
                )
              ORDER BY e.day ASC LIMIT 1
            )
          )
        ",

        :conditions => ['t.user_id = ? AND ti.category_id IN (?)', self.user.id, categories_to_sum]
      }
    else
      {
        :select => 'ti.value',
        :from => 'transfer_items as ti',
        :joins => 'INNER JOIN transfers AS t ON ti.transfer_id = t.id',
        :group => 'ti.currency_id',
        :conditions =>['t.user_id = ? AND ti.category_id IN (?)', self.user.id, categories_to_sum]
      }
    end
  end

  def get_categories_id(with_subcategories)
    categories_to_sum = [self]
    if with_subcategories
      categories_to_sum += descendants
    end
    categories_to_sum.map! {|cat| cat.id}
  end


end
