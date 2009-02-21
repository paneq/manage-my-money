# == Schema Information
# Schema version: 20090221110740
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
#  import_guid       :string(255)   
#  imported          :boolean       
#  type              :string(255)   
#  email             :string(255)   
#  bankinfo          :text          
#

   

require 'hash'
require 'hash_enums'

class Category < ActiveRecord::Base
  extend HashEnums

  define_enum :category_type, [:ASSET, :INCOME, :EXPENSE, :LOAN, :BALANCE]

  acts_as_nested_set :scope=> [:user_id, :category_type_int], :dependent => :destroy

  attr_accessor :opening_balance, :opening_balance_currency

  attr_accessor :parent_guid #for importing, not saved in db

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

  has_many :category_report_options, :foreign_key => :category_id, :dependent => :destroy
  has_many :multiple_category_reports, :through => :category_report_options

  attr_reader :opening_balance, :opening_balance_currency

  validates_presence_of :name
  validates_numericality_of :opening_balance, :allow_nil => true
  validates_presence_of :opening_balance_currency , :unless => proc { |category| category.opening_balance.nil? }
  validate :type_validation

  def <=>(category)
    name <=> category.name
  end


  #Zwraca nazwę kategorii wraz ze ścieżka utworzoną ze wszystkich jej nadkategorii
  #np dla kategorii Owoce -> Wydatki:Jedzenie:Owoce
  def name_with_path
    path = self_and_ancestors.inject('') { |sum, cat| sum += cat.name + ':'}
    path[0,path.size-1]
  end

  def name_with_indentation
    '.'*level + name
  end

  def short_name_with_indentation
    '&nbsp;'*level*2 + short_name
  end


  def short_name
    name[0,15]
  end


  def parent=(element)
    @parent_to_save = element
    self.category_type_int = element.category_type_int
  end


  def after_save
    if @parent_to_save && @parent_to_save != self.parent
      self.move_to_child_of(@parent_to_save)
      @parent_to_save = nil
    end
  end


  #Required for rails validation of fields that are not in database
  def opening_balance_before_type_cast
    @opening_balance
  end
  #Required for rails validation of fields that are not in database
  def opening_balance_currency_before_type_cast
    @opening_balance_currency
  end
  def opening_balance=(ob)
    @opening_balance = ob unless ob.blank? #so => allow_nil works properly
  end
  def opening_balance_currency=(obc)
    @opening_balance_currency = obc unless obc.blank?
  end
  def opening_balance_currency_id
    return @opening_balance_currency.id if @opening_balance_currency.is_a? Currency
  end
  def opening_balance_currency_id=(currency_id)
    self.opening_balance_currency= Currency.find_by_id(currency_id)
  end



  def after_create
    if @opening_balance && @opening_balance_currency
      currency = @opening_balance_currency
      value = @opening_balance
      transfer = Transfer.new(:day =>Date.today, :user => self.user, :description => "Bilans otwarcia")

      transfer.transfer_items.build(:description => transfer.description, :value => value, :category => self, :currency => currency)
      ti = transfer.transfer_items[0]
      transfer.transfer_items.build(:description => transfer.description, :value => (-1 * ti.value), :category => self.user.balance, :currency => currency)
      transfer.save!
      
      @opening_balance = nil
      @opening_balance_currency = nil
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


  def type_validation
    if self.type == LoanCategory.to_s && !can_become_loan_category?
      errors.add(:base, "Tylko nienajwyższa kategoria typu 'Zobowiązania' może reprezentować Dłużnika lub Wierzyciela")
    end
  end


  def before_validation
    if self.description.nil? or self.description.empty?
      self.description = " " #self.type.to_s + " " + self.name  
    end
  end


  def is_top?
    root?
  end


  def can_become_loan_category?
    new_or_old_parent = @parent_to_save || self.parent
    return !(new_or_old_parent.nil? || self.category_type != :LOAN)
  end


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

      value = t.read_attribute('value_for_currency').to_f.round(2)

      if self.user.invert_saldo_for_income && self.category_type == :INCOME
        value = -value
      end


      currency = Currency.find(t.read_attribute('currency_id'))

      if last_transfer != t
        list << {:transfer => t, :money => Money.new()}
      end
      list.last[:money].add!(value, currency)
      last_transfer = t
    end
    
    saldo = saldo_at_end_of_day(start_day - 1.day, :show_all_currencies, with_subcategories)
    for t in list do
      saldo.add!(t[:money])
      t[:saldo] = saldo.clone
    end

    return list;
  end


  # Oblicza udzial wartosci podkategorii w kategorii
  # 
  # Parametry:
  #  share_type to jedno z [:percentage, :value] do usuniecia - nie obliczaj procentow, zawsze podawaj wartosci
  #  max_values_count liczba największych wartości do uwzględnienia do uwzglednienia, pozostale podkategorie znajduja sie w wartosci 'pozostale'
  #  depth stopien zaglebienia w podkategorie w obliczeniach
  #    mozliwe wartosci: 0,1,2,3,4,5,6, :all
  #    0 oznacza zerowe zaglebienie, tzn pokaz oblicz tylko te kategorie z podkategoriami
  #    :all oznacza
  #  period_start, period_end zakres czasowy
  #
  # Wyjscie:
  #  hash tablicy hashy postaci
  #  {currency => [{category=>a_category,with_subcategories => true/false, value => 123.21}, (...) ]}
  #  sortowanie od najwiekszej wartosci waramch waluty
  def calculate_max_share_values(max_values_count, depth, period_start, period_end)
    values = calculate_share_values(depth, period_start, period_end)

    values_in_currencies = {}

    values.map{|v| v[:value].currencies}.flatten.uniq.each do |cur|
      values.sort! {|one,two| two[:value].value(cur)<=>one[:value].value(cur)} #sort from biggest to lowest
      min_value = values.map{|a| a[:value].value(cur)}.uniq[0..(max_values_count-1)].last

      values_to_show, other_values = values.partition {|v| v[:value].value(cur) >= min_value}
      values_to_show << {:category => nil, :value => other_values.sum(Money.new){|v| v[:value]}, :without_subcategories => false}
      values_to_show.delete_if {|el| el[:value].value(cur) == 0}
      values_in_currencies[cur] = values_to_show
    end
    values_in_currencies
  end

  #
  def calculate_share_values(depth, period_start, period_end)
    result = []
    if self.leaf? || depth == 0
      result << {:category => self, :without_subcategories => false, :value => self.saldo_for_period_with_subcategories(period_start, period_end)}
    elsif depth == :all
      result << {:category => self, :without_subcategories => true, :value => self.saldo_for_period_new(period_start, period_end)}
      self.children.each do |sub_category|
        result += sub_category.calculate_share_values(depth, period_start, period_end)
      end
    elsif depth > 0
      result << {:category => self, :without_subcategories => true, :value => self.saldo_for_period_new(period_start, period_end)}
      self.children.each do |sub_category|
        result += sub_category.calculate_share_values(depth-1, period_start, period_end)
      end
    end
    result
  end



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

    flow_categories.map! do |cat|
      cur = Currency.find(cat.read_attribute('currency_id'))
      {
        :category => cat,
        :currency => cur,
        :value => Money.new(cur, cat.read_attribute('sum_value').to_f.round(2))
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
        money.add!(value.round(2), currency)
      else
        # calculated to one value in default currency
        money.add!(set.to_f.round(2), Currency.find_by_id(self.user.default_currency))
      end
    end

    if self.user.invert_saldo_for_income && self.category_type == :INCOME
      money = Money.new - money
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
