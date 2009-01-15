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

# == Schema algorithmrmation
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

  def <=>(category)
    name <=> category.name
  end


  #TODO
  #Dla celow widoku przydała by się taka funkcja 
  #która zwracała by nazwę kategorii wraz ze ścieżka utworzoną ze wszystkich jej nadkategorii
  #np dla kategorii Owoce -> Wydatki:Jedzenie:Owoce
  def name_with_path
    ':'+name
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

  #  # @description: Return a table of transfers that happend between given parameters.
  #  #               Including the start_day and the end_day !
  #  def transfers_between( start_day = :default , end_day = :default)
  #    return transfers.between_or_equal_dates(start_day, end_day).uniq
  #  end
  #
  #
  #  def transfers_from_subcategories_between( start_day = :default , end_day = :default)
  #    t = []
  #    tree_with_parent().each { |c|  t+= c.transfers_between(start_day, end_day) }
  #    t.uniq!
  #    return t
  #  end
  #
  #
  #  # @descriptioin : Return a table o hashes that contains :saldo and :transfer related to that saldo
  #  #                 The collection is sorted by day of transfer and returns also a period_saldo
  #  def transfers_with_saldo_between( start_day = :default , end_day = :default )
  #    transfers_with_chooseable_saldo_between( false, start_day, end_day )
  #  end
  #
  #
  #  # @descriptioin : Return a table o hashes that contains :saldo and :transfer related to that saldo
  #  #                 The collection is sorted by day of transfer and returns also a period_saldo
  #  def transfers_with_subcategories_saldo_between( start_day = :default , end_day = :default )
  #    transfers_with_chooseable_saldo_between( true, start_day, end_day )
  #  end
  #
  #
  #
  #  # @descriptioin : Return a table o hashes that contains :saldo and :transfer related to that saldo
  #  #                 The collection is sorted by day of transfer and returns also a period_saldo
  #  def transfers_with_chooseable_saldo_between( subcategories_saldo = false , start_day = :default , end_day = :default )
  #    if start_day.:default? or end_day.:default?
  #      start_day = :default
  #      end_day = :default
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
  #  def value_with_chooseable_subc(start_day = :default , end_day = :default, subc = true)
  #    return value_with_subcategories( start_day, end_day) if subc
  #    return value(start_day, end_day)
  #  end
  #
  #
  #  def value ( start_day = :default , end_day = :default )
  #    if ( !start_day.:default? and !end_day.:default? )
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
  #  def value_with_subcategories( start_day = :default , end_day = :default )
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
  #  def algorithm( start_day = :default , end_day = :default)
  #    v = transfers_between(start_day , end_day).collect{|t| t.value_by_category(self)}.sum
  #
  #    h = {}
  #    h[:only_value] = v
  #    h[:category] = self
  #    tb = []
  #    child_categories.each do |c|
  #      algorithmrmation = c.algorithm( start_day , end_day )
  #      v += algorithmrmation[:value]
  #      tb << algorithmrmation
  #    end
  #    h[:sub_categories] = tb
  #    h[:value] = v
  #    return h
  #  end
  
  #rupert should be ok
  #@description: return hash with :tree_value, :value, :sub_categories, :category
  #  def algorithm2( start_day = :default , end_day = :default)
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
  #      algorithmrmation = c.algorithm(start_day, end_day)
  #      result[:tree_value] += algorithmrmation[:tree_value]
  #      result[:subcategories] << algorithmrmation
  #    end
  #    return result
  #  end
  
  
  
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
  
 
  def saldo_new(algorithm=:default)
    universal_saldo(algorithm)
  end

  
  def saldo_at_end_of_day(day, algorithm=:default)
    universal_saldo(algorithm, 't.day <= ?', day)
  end


  def saldo_for_period_new(start_day, end_day, algorithm=:default)
    universal_saldo(algorithm, 't.day >= ? AND t.day <= ?', start_day, end_day)
  end


  def saldo_after_day_new(day, algorithm=:default)
    universal_saldo(algorithm, 't.day > ?', day)
  end


  def current_saldo(algorithm=:default)
    saldo_at_end_of_day(Date.today, algorithm)
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
    last_transfer = :default
    for t in transfers do
      if last_transfer == t
        list.last[:money].add(t.read_attribute('value_for_currency').to_i , Currency.find(t.read_attribute('currency_id')))
      else
        list << {:transfer => t, :money => Money.new(Currency.find(t.read_attribute('currency_id')) => t.read_attribute('value_for_currency').to_i )}
      end
      last_transfer = t
    end
    
    saldo = saldo_at_end_of_day(start_day - 1.day, :show_all_currencies)
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
  # Podaje saldo/salda kategorii w podanym czasie
  #
  # Parametry:
  #  inclusion_type to jedno z [:category_only, :subcategory_only, :both]
  #  period_division to jedno z [:day, :week, :none] (lista niedokończona) podzial podanego zakresu czasu na podokresy
  #  period_start, period_end zakres czasowy
  #
  # Wyjscie:
  #  tablica wartosci postaci:
  #  [1,2,3]
  #  w szczegolnym przypadku tablica moze byc jednoelementowa, np gdy period_division == :none
  #  sortowanie od najstarszej wartosci
  #
  def calculate_values(inclusion_type, period_division, period_start, period_end)
    [1,2,3]
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
    ['tydzien1','tydzien2','tydzien3']
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



  def universal_saldo(algorithm = :default, additional_condition="", *params)
    algorithm = algorithm(algorithm)
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


  def algorithm(algorithm)
    return case algorithm
    when :default
      algorithm(self.user.multi_currency_balance_calculating_algorithm)
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
        :conditions => ['t.user_id = ? AND ti.category_id = ?', self.user.id, self.id]
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

        :conditions => ['t.user_id = ? AND ti.category_id = ?', self.user.id, self.id]
      }
    else
      {
        :select => 'ti.value',
        :from => 'transfer_items as ti',
        :joins => 'INNER JOIN transfers AS t ON ti.transfer_id = t.id',
        :group => 'ti.currency_id',
        :conditions =>['t.user_id = ? AND ti.category_id = ?', self.user.id, self.id]
      }
    end
  end
end
