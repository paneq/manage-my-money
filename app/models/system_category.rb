# == Schema Information
# Schema version: 20090320114536
#
# Table name: system_categories
#
#  id                :integer       not null, primary key
#  name              :string(255)   not null
#  parent_id         :integer       
#  lft               :integer       
#  rgt               :integer       
#  created_at        :datetime      
#  updated_at        :datetime      
#  description       :string(255)   
#  category_type_int :integer       
#

require 'hash_enums'

class SystemCategory < ActiveRecord::Base
  extend HashEnums

  has_and_belongs_to_many :categories

  acts_as_nested_set

  validates_presence_of :name, :category_type

  define_enum :category_type, [:ASSET, :INCOME, :EXPENSE, :LOAN, :BALANCE]

  default_scope :order => "category_type_int, lft"

  def name_with_indentation
    '..'*level + name
  end

  named_scope :of_type, lambda { |type|
    raise "Unknown system category type: #{type}" unless SystemCategory.CATEGORY_TYPES.include?(type)
    { :conditions => {:category_type_int => SystemCategory.CATEGORY_TYPES[type] }}
  }



  def self.create_or_update(options = {})
    id = options.delete(:id)
    record = find_by_id(id) || new
    record.id = id
    record.attributes = options
    record.category_type ||= :BALANCE #we set this default type, because we must set it before save, but in the end this type will be set with root record type
    record.save!

    if block_given?
      children_array = []
      yield(children_array)
      children_array.sort!{|a,b| a.name <=> b.name}
      children_array.each do |child|
        child.move_to_child_of(record)
      end
    end

    unless record.category_type_int.nil?
      record.descendants.each do |a|
        a.category_type_int = record.category_type_int
        a.save!
      end
    end

    record
  end


  def self.find_all_by_category_type(category)
    all :conditions => {:category_type_int => category.category_type_int}
  end


end
