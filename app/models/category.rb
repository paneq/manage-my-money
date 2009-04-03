# == Schema Information
# Schema version: 20090330164910
#
# Table name: categories
#
#  id                  :integer       not null, primary key
#  name                :string(255)   not null
#  description         :string(255)   
#  category_type_int   :integer       
#  user_id             :integer       
#  parent_id           :integer       
#  lft                 :integer       
#  rgt                 :integer       
#  import_guid         :string(255)   
#  imported            :boolean       
#  type                :string(255)   
#  email               :string(255)   
#  bankinfo            :text          
#  bank_account_number :string(255)   
#  created_at          :datetime      
#  updated_at          :datetime      
#

class Category < ActiveRecord::Base
  extend HashEnums

  define_enum :category_type, [:ASSET, :INCOME, :EXPENSE, :LOAN, :BALANCE]

  acts_as_nested_set :scope=> [:user_id, :category_type_int], :dependent => :destroy

  attr_accessor :opening_balance, :opening_balance_currency, :new_subcategories

  attr_accessor :parent_guid #for importing, not saved in db

  belongs_to :user

  named_scope :top, :conditions => ['parent_id IS NULL']
  named_scope :of_type, lambda { |type|
    raise "Unknown category type: #{type}" unless Category.CATEGORY_TYPES.include?(type)
    { :conditions => {:category_type_int => Category.CATEGORY_TYPES[type] }}
  }


  named_scope :with_level, :select => 'categories.*, (
    SELECT
      count(*)
    FROM
      categories as c2
    where
      c2.id != categories.id AND
      c2.lft <= categories.lft AND
      c2.rgt >= categories.rgt AND
      c2.user_id = categories.user_id AND
      c2.category_type_int = categories.category_type_int
  ) as cached_level'



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

  has_and_belongs_to_many :system_categories


  attr_reader :opening_balance, :opening_balance_currency

  validates_presence_of :name
  validates_numericality_of :opening_balance, :allow_nil => true
  validates_presence_of :opening_balance_currency , :unless => proc { |category| category.opening_balance.nil? }
  validate :type_validation
  validates_format_of :email, :allow_nil => true, :allow_blank => true, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i #should be in LoanCategory but cannot be
  validate :system_category_type_validation

  def <=>(category)
    name <=> category.name
  end


  #Zwraca nazwę kategorii wraz ze ścieżka utworzoną ze wszystkich jej nadkategorii
  #np dla kategorii Owoce -> Wydatki:Jedzenie:Owoce
  def name_with_path
    @double_cached_name_with_path ||= Rails.cache.fetch(name_with_path_cache_key) do
      path = self_and_ancestors.inject('') { |sum, cat| sum += cat.name + ':'}
      path[0,path.size-1]
    end
    @double_cached_name_with_path
  end

  def cached_level
    ca_level = read_attribute('cached_level')
    unless ca_level.blank?
      Integer(ca_level)
    else
      Rails.cache.fetch(level_cache_key) { level }
    end
  end

  def level_cache_key
    "category(#{user_id},#{id}).level"
  end

  def name_with_path_cache_key
    "category(#{user_id},#{id}).name_with_path"
  end

  def clear_cache
    @double_cached_name_with_path = nil
    Rails.cache.delete(level_cache_key)
    Rails.cache.delete(name_with_path_cache_key)
  end



  def name_with_indentation
    '.'*cached_level + name
  end

  def short_name_with_indentation
    '&nbsp;'*cached_level*2 + short_name
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


  def save_with_subcategories!
    @was_new_record_before_save = new_record?
    transaction do
      save!
      save_new_subcategories!
    end
  end

  def save_with_subcategories
    begin
      save_with_subcategories!
    rescue
      instance_variable_set("@new_record", true) if @was_new_record_before_save #HACK HACK HACK
      return false
    else
      return true
    end
  end

  def save_new_subcategories!
    #0 retrieve selected categories
    selected_categories = new_subcategories.map do |sys_cat_id|
      SystemCategory.find(sys_cat_id.to_i)
    end.compact

    categories_pairs = {}
    selected_categories.each do |selected_category|
      #1 fix system_categories parents
      if (selected_category.new_parent != nil) && (!selected_categories.include?(selected_category.new_parent))
        selected_category.new_parent = find_first_selected_parent(selected_categories, selected_category)
      end

      #2 create new_categories in hash
      categories_pairs[selected_category] = new_from_system_category(self, selected_category)
    end

    #3 set new categories parents
    categories_pairs.keys.sort_by(&:cached_level).each do |selected_category|
      new_subcategory = categories_pairs[selected_category]
      new_subcategory.parent = categories_pairs[selected_category.new_parent] || self
      unless new_subcategory.valid?
        errors.add(:base,"Błąd przy tworzeniu podkategorii: #{new_subcategory.name} - #{new_subcategory.errors.full_messages}")
      end
      new_subcategory.save!
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

  def system_category_type_validation
    if !self.system_category.nil? && self.category_type != self.system_category.category_type
      errors.add(:base, 'Kategoria systemowa powinna być tego samego typu nadrzędnego co dana kategoria')
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
    transfers = Transfer.send(:with_exclusive_scope) do
      Transfer.find(
        :all,
        :select =>      'transfers.id, min(transfers.day) as mday, sum(transfer_items.value) as value_for_currency, transfer_items.currency_id as currency_id',
        :joins =>       'INNER JOIN transfer_items on transfer_items.transfer_id = transfers.id',
        :group =>       'transfers.id, transfer_items.currency_id',
        :conditions =>  ['transfer_items.category_id IN (?) AND transfers.day >= ? AND transfers.day <= ?', categories, start_day, end_day],
        :order =>       'mday, transfers.id, transfer_items.currency_id')
    end
    transfers_full = Transfer.find(:all, :conditions => ['id IN (?)', transfers.map{|t| t.id}])
    array = []
    attributes = %w(value_for_currency currency_id)
    transfers.each do |t|
      new = transfers_full.find{|f| f.id == t.id}
      clonned = new.clone
      clonned.id = new.id
      attributes.each do |atr|
        clonned.write_attribute(atr, t.read_attribute(atr))
      end
      array << clonned
    end
    transfers = array

    list = []
    last_transfer = nil
    currencies = {}
    for t in transfers do

      value = t.read_attribute('value_for_currency').to_f.round(2)

      if self.user.invert_saldo_for_income && self.category_type == :INCOME
        value = -value
      end

      cur_id = t.read_attribute('currency_id')
      currencies[cur_id] ||= Currency.find(cur_id)
      currency = currencies[cur_id]

      if last_transfer.nil? || last_transfer.id != t.id
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
      :select =>      'categories.id,
                       ti2.value >=0 as income,
                       ti2.currency_id,
                       sum(abs(ti2.value)) as sum_value',
      :from => 'transfers as t',
      :joins =>       
        'INNER JOIN transfer_items ti2 on ti2.transfer_id = t.id
                       INNER JOIN categories on ti2.category_id = categories.id',
                       
      :group =>       'categories.id,
                       ti2.currency_id,
                       ti2.value >= 0',
      :conditions =>  ['ti2.category_id not in (?)
                        AND t.day >= ?
                        AND t.day <= ?
                        AND t.id IN (SELECT DISTINCT tt.id FROM transfers as tt INNER JOIN transfer_items as ti1 ON ti1.transfer_id = tt.id WHERE ti1.category_id in (?) )',
        categories, period_start, period_end, categories]
    )
    newf = Category.find(:all, :conditions => ['id IN (?)', flow_categories.map{|c| c.id}.uniq], :order => 'category_type_int, lft')
    array = []
    attributes = ['income', 'sum_value', 'currency_id']
    flow_categories.each do |c|
      new = newf.find { |f| f.id == c.id }
      xyz = new.clone
      xyz.id = new.id
      attributes.each do |atr|
        xyz.write_attribute(atr, c.read_attribute(atr))
      end
      array << xyz
    end
    flow_categories = array.sort{|a,b| [a.category_type_int, a.lft] <=>[b.category_type_int, b.lft]}


    currencies = {}
    flow_categories.map! do |cat|
      cur_id = cat.read_attribute('currency_id')
      currencies[cur_id] ||= Currency.find(cur_id)
      cur = currencies[cur_id]
      {
        :category => cat,
        :currency => cur,
        :value => Money.new(cur, cat.read_attribute('sum_value').to_f.round(2))
      }
    end

    cash_in, cash_out = flow_categories.partition { |cat_hash| cat_hash[:category].read_attribute('income') == SqlDialects.get_false }#'f'}

    {:out => cash_out, :in => cash_in}
  end


  #wartośc moze nie miec sensu jesli w kategorii nadrżednej są kategorie o saldach o róznych znakach
  def percent_of_parent_category(period_start, period_end, include_subcategories)

    #TODO stop if top category

    parent_value = self.parent.saldo_for_period_new(period_start, period_end, :default, true)
    self_value = self.saldo_for_period_new(period_start, period_end, :default, include_subcategories)


    currency = self.user.default_currency

    self_value = self_value.value(currency)

    parent_value = parent_value.value(currency)

    if parent_value == 0
      return 0
    else
      return (self_value/parent_value*100).round(2)
    end

  end

  def system_category_id=(sys_category_id)
    unless sys_category_id.blank?
      self.system_category=(SystemCategory.find(sys_category_id))
    else
      self.system_category= nil
    end
  end


  def system_category_id
    unless self.system_category.nil?
      self.system_category.id
    else
      nil
    end
  end


  def system_category=(sys_category)
    if sys_category.nil?
      self.system_category_ids=[]
    else
      self.system_category_ids= sys_category.self_and_ancestors.map{|a|a.id}
    end
  end


  def system_category
    self.system_categories.max_by(&:cached_level)
  end

  def self.autocomplete(text, user = nil)

    with_exclusive_scope do
      found = find(:all,
        :select => 'categories.id, count(*) as number', #, system_categories.parent_id
        :joins => '
        JOIN categories_system_categories   AS my_csc             ON    categories.id                 =   my_csc.category_id
        JOIN categories_system_categories   AS other_csc          ON    my_csc.system_category_id     =   other_csc.system_category_id
        JOIN categories                     AS other_categories   ON    other_csc.category_id         =   other_categories.id
        JOIN transfer_items                                       ON    other_categories.id           =   transfer_items.category_id',
        :conditions => ['other_categories.user_id != ? AND
          categories.user_id = ? AND
          transfer_items.id IN (?) AND
          my_csc.system_category_id =
          (SELECT MAX(inner_csc.system_category_id)
          FROM categories_system_categories as inner_csc
          WHERE inner_csc.category_id = categories.id)',
          user.id,
          user.id,
          TransferItem.search_for_ids(text)],
        :group => 'categories.id',
        :order => 'number DESC',
        :limit => 5
      )
      Category.find(:all, :conditions => {:id => found.map(&:id)})
    end

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
    currencies = {}

    TransferItem.sum(:value, algorithm).each do |set|
      if set.class == Array
        # group by currency
        currency, value = set
        currencies[currency] ||= Currency.find_by_id(currency)
        currency = currencies[currency]
        money.add!(value.round(2), currency)
      else
        # calculated to one value in default currency
        money.add!(set.to_f.round(2), self.user.default_currency)
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
        WHEN ex.left_currency_id = #{currency.id} THEN ti.value*ex.right_to_left
        WHEN ex.left_currency_id != #{currency.id} THEN ti.value*ex.left_to_right
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
                abs( #{SqlDialects.get_date('t.day')} - #{SqlDialects.get_date('e.day')} ) =
                  (
                  SELECT min( abs( #{SqlDialects.get_date('t.day')} - #{SqlDialects.get_date('e2.day')} ) ) FROM exchanges as e2 WHERE
                    (
                    (e2.user_id = #{self.user.id} ) AND
                    (e2.left_currency_id = #{currency.id} AND e2.right_currency_id = ti.currency_id) OR (e2.left_currency_id = ti.currency_id AND e2.right_currency_id = #{currency.id})
                    )
                  )
                AND
                  (
                  (e.left_currency_id = #{currency.id} AND e.right_currency_id = ti.currency_id) OR (e.left_currency_id = ti.currency_id AND e.right_currency_id = #{currency.id})
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
        WHEN ex.left_currency_id = #{currency.id} THEN ti.value*ex.right_to_left
        WHEN ex.left_currency_id != #{currency.id} THEN ti.value*ex.left_to_right
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
                abs( #{SqlDialects.get_today} - #{SqlDialects.get_date('e.day')} ) =
                  (
                  SELECT min( abs( #{SqlDialects.get_today} - #{SqlDialects.get_date('e2.day')} ) ) FROM Exchanges as e2 WHERE
                    (
                    (e2.user_id = #{self.user.id} ) AND
                    ((e2.left_currency_id = #{currency.id} AND e2.right_currency_id = ti.currency_id) OR (e2.left_currency_id = ti.currency_id AND e2.right_currency_id = #{currency.id}))
                    )
                  )
                AND
                  (
                  (e.left_currency_id = #{currency.id} AND e.right_currency_id = ti.currency_id) OR (e.left_currency_id = ti.currency_id AND e.right_currency_id = #{currency.id})
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


  protected
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


  def find_first_selected_parent(selected_categories, selected_category)
    selected_ancestors = selected_category.ancestors.find_all{ |ancestor| selected_categories.include?(ancestor) }

    if selected_ancestors.empty?
      nil
    else
      selected_ancestors.max_by{ |selected_ancestor| selected_ancestor.cached_level}
    end
  end


  def new_from_system_category(parent, system_category)
    new_category = Category.new
    new_category.name = system_category.name
    new_category.description = system_category.description
    new_category.category_type_int = system_category.category_type_int
    new_category.system_category = system_category
    new_category.user_id = parent.user_id
    new_category
  end



end
