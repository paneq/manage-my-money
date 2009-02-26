# == Schema Information
# Schema version: 20090226180602
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
  
  after_update :save_transfer_items

  validates_associated :transfer_items
  validates_presence_of :day
  validates_presence_of :user

  def new_transfer_items_attributes=(transfer_items_attributes)
    transfer_items_attributes.each do |attributes|
      transfer_items.build(attributes[1].merge(:error_id =>attributes[0]))
    end
  end


  def existing_transfer_items_attributes=(transfer_items_attributes)
    transfer_items.reject(&:new_record?).each do |transfer_item|
      attributes = transfer_items_attributes[transfer_item.id.to_s]
      if attributes
        transfer_item.attributes = attributes
      else
        transfer_items.delete(transfer_item)
      end
    end
  end


  def save_transfer_items
    transfer_items.each do |transfer_item|
      transfer_item.save(false)
    end
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
