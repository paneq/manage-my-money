# == Schema Information
# Schema version: 20090414090944
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
#  email               :string(255)   
#  bankinfo            :text          
#  bank_account_number :string(255)   
#  created_at          :datetime      
#  updated_at          :datetime      
#  loan_category       :boolean       
#

class Category < ActiveRecord::Base
  extend HashEnums

  attr_protected :user_id, :category_type_int

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

  named_scope :people_loans, :conditions => {:loan_category => true}

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
  ) as cached_category_level'

  
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

  has_many :goals, :dependent => :destroy

  has_many :category_report_options, :foreign_key => :category_id, :dependent => :destroy
  has_many :multiple_category_reports, :through => :category_report_options

  has_and_belongs_to_many :system_categories


  attr_reader :opening_balance, :opening_balance_currency

  validates_presence_of :name
  validates_presence_of :user
  validates_numericality_of :opening_balance, :allow_nil => true
  validates_presence_of :opening_balance_currency , :unless => proc { |category| category.opening_balance.nil? }
  validate :type_validation
  validates_format_of :email, :allow_nil => true, :allow_blank => true, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :if => proc {|category| category.loan_category}
  validate :system_category_type_validation
  #validates_uniqueness_of :name, :scope => [:user_id, :category_type_int, :parent_id] It does not work becuase the element is moved to proper parent in after_create action...

  def <=>(category)
    name <=> category.name
  end


  #Zwraca nazwę kategorii wraz ze ścieżka utworzoną ze wszystkich jej nadkategorii
  #np dla kategorii Owoce -> Wydatki:Jedzenie:Owoce
  def name_with_path
    @double_cached_name_with_path ||= Rails.cache.fetch(name_with_path_cache_key) do
      self_and_ancestors.map(&:name).join(':')
    end
    @double_cached_name_with_path
  end

  def cached_level
    ca_level = read_attribute('cached_category_level')
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
    if element.is_a?(Category)
      @parent_to_save = element
      self.category_type_int = element.category_type_int
    end
  end


  def after_save
    if @parent_to_save && @parent_to_save != self.parent && move_possible?(@parent_to_save) #Cannot check it because it is always top until moved... && !self.is_top?
      self.move_to_child_of(@parent_to_save)
      @parent_to_save = nil
    end
  end


  ##Try to save category and given subcategories (from new_subcategories attribute) in transaction
  #rollback all in case of failure
  def save_with_subcategories
    @was_new_record_before_save = new_record? #saving new_record? value, for eventually use in case of rollback
    transaction do
      save!
      save_new_subcategories!
    end
    return true
  rescue
    instance_variable_set("@new_record", true) if @was_new_record_before_save #revert previous new_record? value
    return false
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

  def after_create
    if @opening_balance && @opening_balance_currency
      currency = @opening_balance_currency
      value = Kernel.BigDecimal(@opening_balance.to_s)
      value *= -1 if self.user.invert_saldo_for_income && self.category_type == :INCOME
      transfer = Transfer.new(:day =>Date.today, :user => self.user, :description => "Bilans otwarcia")

      transfer.transfer_items.build(:description => transfer.description, :value => value, :category => self, :currency => currency)
      ti = transfer.transfer_items[0]
      transfer.transfer_items.build(:description => transfer.description, :value => (-1 * ti.value), :category => self.user.balance, :currency => currency)
      transfer.save!
      
      @opening_balance = nil
      @opening_balance_currency = nil
    end
  end

  # maybe using ActiveSupport::Callbacks would work and be a better solution, maybe somehow...
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

    Report.update_all("category_id = NULL", {:type => "ShareReport", :category_id => self.id})
    TransferItem.update_all("category_id = #{self.parent.id}", "category_id = #{self.id}")

    # Moving children makes SQL queries that updates current object lft and rgt fields.
    # Becuase of that we need to update it calling reload_nested_set so valid fields are stored
    # and another sql queries are exectued with valid values -> queries that destroy children
    reload_nested_set
    original_destroy

  end


  def type_validation
    if self.loan_category && !can_become_loan_category?
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


  def recent_unbalanced
    saldo = self.current_saldo(:default)
    twenty = self.transfers.find(:all, :limit => 20, :order => 'transfers.day DESC, transfers.id DESC', :include => :transfer_items)
    transfers = []
    number = 0
    size = twenty.size
    currencies = {}

    while(!saldo.empty? && number < size)
      transfer = twenty[number]
      transfers << {:transfer => transfer, :saldo => saldo.clone}
      items = transfer.transfer_items.select{|ti| ti.category_id == self.id }
      items.each do |item|
        currencies[item.currency_id] ||= Currency.find(item.currency_id)
        saldo.sub!(item.value, currencies[item.currency_id])
      end
      number += 1
    end

    transfers.reverse!
    return transfers
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
        :value => Money.new(cur, Kernel.BigDecimal(cat.read_attribute('sum_value')).round(2))
      }
    end

    cash_in, cash_out = flow_categories.partition { |cat_hash| cat_hash[:category].read_attribute('income') == SqlDialects.get_false }#'f'}

    {:out => cash_out, :in => cash_in}
  end


  #wartośc moze nie miec sensu jesli w kategorii nadrżednej są kategorie o saldach o róznych znakach
  def percent_of_parent_category(period_start, period_end, include_subcategories)

    #TODO stop if top category

    parent_value = self.parent.saldo_for_period(period_start, period_end, :default, true)
    self_value = self.saldo_for_period(period_start, period_end, :default, include_subcategories)


    currency = self.user.default_currency

    self_value = self_value.value(currency)

    parent_value = parent_value.value(currency)

    if parent_value == 0
      return 0
    else
      return (self_value/parent_value*100).round(2)
    end

  end


  # Returns money
  def saldo(algorithm=:default, with_subcategories = false)
    Category.compute(algorithm, self.user, self, with_subcategories, nil)[self]
  end


  # Returns money
  def saldo_at_end_of_day(day, algorithm=:default, with_subcategories = false)
    Category.compute(algorithm, self.user, self, with_subcategories, day)[self]
  end


  # Returns money
  def saldo_for_period(start_day, end_day, algorithm=:default, with_subcategories = false)
    Category.compute(algorithm, self.user, self, with_subcategories, Range.new(start_day, end_day))[self]
  end

  # Returns money
  def current_saldo(algorithm=:default)
    saldo_at_end_of_day(Date.today, algorithm)
  end


  # TODO: Returns ...
  def transfers_with_saldo(algorithm, with_subcategories, range_or_number)
    sql = transfers_with_saldo_sql(algorithm, with_subcategories, range_or_number)

    quick_curr = {}
    Currency.for_user(user).each do |cur|
      quick_curr[cur.id.to_s] = cur
    end

    compute_saldo = case range_or_number
    when Range then self.saldo_at_end_of_day(range_or_number.end, algorithm, with_subcategories)
    when Fixnum then self.saldo(algorithm, with_subcategories)
    end
    

    result = Category.connection.execute(sql)
    result = result.map do |row|
      HashWithIndifferentAccess.new(row.to_hash)
    end

    saldo = compute_saldo.clone
    prev = Money.new
    result.reverse_each do |row|
      row[:money] = Money.new quick_curr[row[:computed_currency]], Kernel.BigDecimal(row[:computed_value])
      row[:saldo] = saldo.sub!(prev).clone
      prev = row[:money]
    end

    result = result.group_by{|row| row[:transfers_id]}
    return result, compute_saldo - (saldo - prev) # saldo is saldo after first transaction on the list, # (saldo - prev) is saldo after last hidden transaction
  end


  def transfers_with_saldo_sql(algorithm, with_subcategories, range_or_number)
    categories = get_categories_id(with_subcategories)
    user = self.user
    algorithm = user.multi_currency_balance_calculating_algorithm if algorithm == :default

    sql = Category.build_top_select()
    sql << Category.build_select()
    sql << Category.build_computed_currency(algorithm, user)
    sql << Category.build_computed_case(algorithm, user) << " AS computed_value,"
    sql << Category.build_number
    sql << Category.build_opposite_id
    sql << "FROM categories"
    sql << Category.build_transfer_items_join(false)
    sql << Category.build_transfers_join
    sql << Category.build_exchanges_join(algorithm, user)
    sql << Category.build_conversion_join(algorithm, user)
    sql << Category.build_inner_where(user, categories, range_or_number)
    sql << Category.build_order()
    sql << Category.build_limit_and_offset(user, categories, range_or_number)
    sql << ") as subq"
    sql << Category.build_categories_join
    sql
  end


  ##
  # if array_or_range_or_date_or_nil is an array ex.: [[date1, date2], [date3, date4], ..] or [date1..date2, date3..date4 ...]
  #  result looks like this:
  #  {
  #  category_obj_1 => {
  #       date_table_or_range_1 => money_obj,
  #       date_table_or_range_2 => money_obj
  #       },
  #  category_obj_2 => {
  #       date_table_or_range_1 => money_obj,
  #       date_table_or_range_2 => money_obj
  #       }
  #  }
  #
  # else
  # result looks like this:
  # {
  #  category_obj_1 => money_obj,
  #  category_obj_2 => money_obj
  # }

  # array_or_range_or_date_or_nil can be:
  # array of two element arrays of dates -> will group results by those periods, will look for transfers with day between first.first and last.last day in array
  # array of date ranges -> will group results by those periods, will look for transfers with day between first.start and last.end day in array
  # range -> will not group result, will look for transfers with day between range.start and range.end
  # date -> will not group result, will look for transfers with day <= date
  # array of transfers.id -> will not group result, will look for transfers with id in array
  #
  # include -> calculate includes transfers for subcategories
  def self.compute(algorithm, user, categories, include, array_or_range_or_date_or_nil = nil)
    categories = [categories] if categories.is_a?(Category)
    sql = compute_sql(algorithm, user, categories, include, array_or_range_or_date_or_nil)

    sql_result = connection.execute(sql)
    ret_result = SequencedHash.new
    
    quick_cat = {}
    quick_time = {}
    quick_curr = {}
    
    Currency.for_user(user).each do |cur|
      quick_curr[cur.id.to_s] = cur
    end

    is_array = array_or_range_or_date_or_nil.is_a?(Array)

    if is_array
      array_or_range_or_date_or_nil.each_with_index do |time, index|
        quick_time[index.to_s] = time
      end
    end

    if is_array
      categories.each do |cat|
        quick_cat[cat.id.to_s] = cat
        ret_result[cat] = SequencedHash.new
        array_or_range_or_date_or_nil.each do |time|
          ret_result[cat][time]  = Money.new()
        end
      end
    else
      categories.each do |cat|
        quick_cat[cat.id.to_s] = cat
        ret_result[cat] = Money.new()
      end
    end

    if is_array
      sql_result.each do |row|
        ret_result[quick_cat[row[0]]][quick_time[row[1]]].add!(Kernel.BigDecimal(row[3]), quick_curr[row[2]])
      end
    else
      sql_result.each do |row|
        ret_result[quick_cat[row[0]]].add!(Kernel.BigDecimal(row[3]), quick_curr[row[2]]) # skip my_group sql column which is always the same when not splitted into period
      end
    end

    ret_result
  end


  def self.compute_sql(algorithm, user, categories, include, array_or_range_or_date_or_nil = nil)
    raise "Invalid algorithm given: #{algorithm}" unless User.MULTI_CURRENCY_BALANCE_CALCULATING_ALGORITHMS.include?(algorithm) || algorithm == :default
    algorithm = user.multi_currency_balance_calculating_algorithm if algorithm == :default
    categories = [categories] if categories.is_a?(Category)
    sql =<<-SQL
      SELECT
      categories.id,
    SQL
    sql << build_my_group(array_or_range_or_date_or_nil)
    sql << build_computed_currency(algorithm, user)
    sql << build_sum(algorithm, user)
    sql << "FROM categories"
    sql << build_subcategories_join if include
    sql << build_transfer_items_join(include)
    sql << build_transfers_join
    sql << build_exchanges_join(algorithm, user)
    sql << build_conversion_join(algorithm, user)
    sql << build_where(user, categories, array_or_range_or_date_or_nil)
    sql << build_group_and_order
    sql
  end

  #======================
  private


  def self.build_top_select()
    "SELECT subq.*, categories.name as categories_name FROM ("
  end

  def self.build_select()
    "
SELECT
 transfers.day as transfers_day,
 transfers.id as transfers_id,
 transfers.description as transfers_description,
 transfer_items.description as transfer_items_description,
    "
  end

  def self.build_number()
    "
(SELECT
   count(*)
  FROM transfer_items as ti2
  WHERE
    transfer_items.transfer_id = ti2.transfer_id
    AND
    transfer_items.id != ti2.id
    AND
    sign(transfer_items.value) != sign(ti2.value)
  ) as number,
    "
  end


  def self.build_opposite_id()
    "
 (SELECT
   min(category_id)
  FROM transfer_items as ti2
  WHERE
    transfer_items.transfer_id = ti2.transfer_id
    AND
    transfer_items.id != ti2.id
    AND
    sign(transfer_items.value) != sign(ti2.value)
  ) as opposite_id
    "
  end


  def self.build_inner_where(user, categories_id, range_or_number)
    where = "WHERE categories.user_id = #{user.id} AND categories.id IN (#{categories_id.join(', ')}) AND transfers.user_id = #{user.id} "
    where << "AND transfers.day >= '#{range_or_number.begin}' AND transfers.day <= '#{range_or_number.end}' " if range_or_number.is_a?(Range)
    where
  end


  def self.build_order()
    "ORDER BY transfers.day, transfers.id, transfer_items.id"
  end


  def self.build_limit_and_offset(user, categories_id, range_or_number)
    return " LIMIT #{range_or_number} OFFSET #{user.transfer_items.count(:conditions => {:category_id => categories_id}) - range_or_number}" if range_or_number.is_a?(Fixnum)
    return ""
  end


  def self.build_categories_join
    "
LEFT JOIN
 categories
ON
 number = 1 AND
 opposite_id = categories.id;
    "
  end


  def self.build_my_group(param)
    return case param
    when Array then
      return "0 as my_group,\n" if param.first.is_a?(Fixnum) || param.first.is_a?(Bignum) # array of transfers.id to look for. In other words: array of integers

      sql_case="CASE\n"
      param.each_with_index do |range_or_array, index|
        case range_or_array
        when Array then
          sql_case << "WHEN transfers.day <= '#{range_or_array[1].to_s}' THEN #{index}\n"
        when Range then
          sql_case << "WHEN transfers.day <= '#{range_or_array.end.to_s}' THEN #{index}\n"
        end
      end
      sql_case << "END as my_group,\n"
      sql_case

    when Range, Date, NilClass, Time then
      "0 as my_group,\n"
    end
  end


  def self.build_computed_currency(algorithm, user)
    if algorithm == :show_all_currencies
      "transfer_items.currency_id as computed_currency,\n"
    else
      "#{user.default_currency.id} as computed_currency,\n"
    end
  end


  def self.build_computed_case(algorithm, user)
    return case algorithm
    when :show_all_currencies then
      if user.invert_saldo_for_income
        "CASE
WHEN categories.category_type_int != #{Category.CATEGORY_TYPES[:INCOME]} THEN transfer_items.value
ELSE transfer_items.value * (-1)
END"
      else
        "transfer_items.value"
      end
    when :calculate_with_newest_exchanges, :calculate_with_exchanges_closest_to_transaction
      value = user.invert_saldo_for_income ? "transfer_items.value * (-1) " : "transfer_items.value"
      currency_id = user.default_currency_id
      "CASE
          WHEN categories.category_type_int != #{Category.CATEGORY_TYPES[:INCOME]} THEN
            transfer_items.value
          ELSE
            #{value}
       END *
       CASE
         WHEN transfer_items.currency_id = #{currency_id} THEN
           1
         WHEN ex.left_currency_id = #{currency_id} THEN
           ex.right_to_left
         WHEN ex.left_currency_id != #{currency_id} THEN
           ex.left_to_right
       END
      "
    when :calculate_with_newest_exchanges_but, :calculate_with_exchanges_closest_to_transaction_but
      value = user.invert_saldo_for_income ? "transfer_items.value * (-1) " : "transfer_items.value"
      currency_id = user.default_currency_id
      "CASE
          WHEN categories.category_type_int != #{Category.CATEGORY_TYPES[:INCOME]} THEN
            transfer_items.value
          ELSE
            #{value}
       END *
       CASE
         WHEN transfer_items.currency_id = #{currency_id} THEN
           1
         WHEN ex2.left_currency_id = #{currency_id} THEN
           ex2.right_to_left
         WHEN ex2.left_currency_id != #{currency_id} THEN
           ex2.left_to_right
         WHEN ex.left_currency_id = #{currency_id} THEN
           ex.right_to_left
         WHEN ex.left_currency_id != #{currency_id} THEN
           ex.left_to_right
       END
      "
    else
      raise 'unimplemented yet'
    end
    
    #TODO: write test to check out that all alghoritms are implemented here...
  end


  def self.build_sum(algorithm, user)
    return "sum(#{build_computed_case(algorithm, user)}) as computed_value\n"
  end


  def self.build_subcategories_join
    "
INNER JOIN categories as c2
  ON (
    c2.user_id = categories.user_id AND
    c2.category_type_int = categories.category_type_int AND
    c2.lft >= categories.lft AND
    c2.rgt <= categories.rgt
  )
    "
  end


  def self.build_transfer_items_join(include)
    if include
      "
INNER JOIN transfer_items
  ON (
    c2.id = transfer_items.category_id
  )
      "
    else
      "
INNER JOIN transfer_items
  ON (
    categories.id = transfer_items.category_id
  )
      "
    end
  end


  def self.build_transfers_join
    "
INNER JOIN transfers
  ON (
    transfer_items.transfer_id = transfers.id
  )
    "
  end


  def self.build_exchanges_join(algorithm, user)
    return '' if algorithm == :show_all_currencies
    currency_id = user.default_currency_id

    today_or_transfer_day = case algorithm
    when :calculate_with_newest_exchanges, :calculate_with_newest_exchanges_but then SqlDialects.get_today
    when :calculate_with_exchanges_closest_to_transaction, :calculate_with_exchanges_closest_to_transaction_but then SqlDialects.get_date('transfers.day')
    else
      raise 'Unexpected algorithm :-)'
    end
    "
LEFT JOIN exchanges as ex ON
(
transfer_items.currency_id != #{currency_id} AND ex.Id IN
  (
    SELECT Id FROM exchanges as e WHERE
      (
      abs( #{today_or_transfer_day} - #{SqlDialects.get_date('e.day')} ) =
        (
        SELECT min( abs( #{today_or_transfer_day} - #{SqlDialects.get_date('e2.day')} ) ) FROM Exchanges as e2 WHERE
          (
          (e2.user_id = #{user.id} ) AND
          ((e2.left_currency_id = #{currency_id} AND e2.right_currency_id = transfer_items.currency_id) OR (e2.left_currency_id = transfer_items.currency_id AND e2.right_currency_id = #{currency_id}))
          )
        )
      AND
        (
        e.user_id = #{user.id}
        )
      AND
        (
        (e.left_currency_id = #{currency_id} AND e.right_currency_id = transfer_items.currency_id) OR (e.left_currency_id = transfer_items.currency_id AND e.right_currency_id = #{currency_id})
        )
      )
    ORDER BY e.day ASC LIMIT 1
  )
)
    "
  end


  def self.build_conversion_join(algorithm, user)
    return '' if [:show_all_currencies, :calculate_with_newest_exchanges, :calculate_with_exchanges_closest_to_transaction].include?(algorithm)
    currency_id = user.default_currency_id
    "
LEFT JOIN conversions ON
(
  (transfers.id = conversions.transfer_id) AND
  (transfer_items.currency_id != #{currency_id})
)
LEFT JOIN exchanges as ex2 ON
(
  (conversions.exchange_id = ex2.id) AND
  (ex2.user_id = #{user.id}) AND
  (
    (ex2.left_currency_id = #{currency_id} AND ex2.right_currency_id = transfer_items.currency_id)
    OR (ex2.left_currency_id = transfer_items.currency_id AND ex2.right_currency_id = #{currency_id})
  )
)"
  end


  def self.build_where(user, categories, array_or_range_or_date_or_nil)
    sql = "WHERE categories.user_id = #{user.id} AND \n"
    sql << "transfers.user_id = #{user.id} AND \n"
    sql << "categories.id IN ( #{ categories.map(&:id).join(', ') } )"
    sql << " AND \n" unless array_or_range_or_date_or_nil.nil?
    case array_or_range_or_date_or_nil
    when Array then

      if array_or_range_or_date_or_nil.first.is_a?(Fixnum) || array_or_range_or_date_or_nil.first.is_a?(Bignum) # array of transfers.id to look for. In other words: array of integers
        sql << "transfers.id IN ( #{array_or_range_or_date_or_nil.join(", ")} )\n"
      else

        first_obj = array_or_range_or_date_or_nil.first
        case first_obj
        when Array
          sql << "transfers.day >= '#{first_obj[0].to_date.to_s}' "
        when Range
          sql << "transfers.day >= '#{first_obj.begin.to_date.to_s}' "
        end

        sql << "AND "

        last_obj = array_or_range_or_date_or_nil.last
        case last_obj
        when Array
          sql << "transfers.day <= '#{last_obj[1].to_date.to_s}' \n"
        when Range
          sql << "transfers.day <= '#{last_obj.end.to_date.to_s}' \n"
        end

      end
    when Range then
      sql << "transfers.day >= '#{array_or_range_or_date_or_nil.begin.to_date.to_s}' AND "
      sql << "transfers.day <= '#{array_or_range_or_date_or_nil.end.to_date.to_s}' \n"

    when Date then
      sql << "transfers.day <= '#{array_or_range_or_date_or_nil.to_s}' "

    when Time then
      sql << "transfers.day <= '#{array_or_range_or_date_or_nil.to_date.to_s}' "
    end

    sql
  end


  def self.build_group_and_order
    "GROUP BY
  categories.id,
  my_group,
  computed_currency
ORDER BY
  categories.id;"
  end
  

  def get_categories_id(with_subcategories)
    categories_to_sum = with_subcategories ? self_and_descendants : [self]
    categories_to_sum.map {|cat| cat.id}
  end


  protected
  def calculate_share_values(depth, period_start, period_end)
    result = []
    if self.leaf? || depth == 0
      result << {:category => self, :without_subcategories => false, :value => self.saldo_for_period(period_start, period_end, :default, true)}
    elsif depth == :all
      result << {:category => self, :without_subcategories => true, :value => self.saldo_for_period(period_start, period_end)}
      self.children.each do |sub_category|
        result += sub_category.calculate_share_values(depth, period_start, period_end)
      end
    elsif depth > 0
      result << {:category => self, :without_subcategories => true, :value => self.saldo_for_period(period_start, period_end)}
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
