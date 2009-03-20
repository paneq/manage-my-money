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

# == Schema Information
# Schema version: 20090313212009
#
# Table name: system_categories
#
#  id         :integer       not null, primary key
#  name       :string(255)   not null
#  parent_id  :integer       
#  lft        :integer       
#  rgt        :integer       
#  created_at :datetime      
#  updated_at :datetime      
#
require 'hash_enums'

class SystemCategory < ActiveRecord::Base
  extend HashEnums

  has_and_belongs_to_many :categories

  acts_as_nested_set

  validates_presence_of :name

  define_enum :category_type, [:ASSET, :INCOME, :EXPENSE, :LOAN, :BALANCE]

  #from http://railspikes.com/2008/2/1/loading-seed-data
  # given a hash of attributes including the ID, look up the record by ID.
  # If it does not exist, it is created with the rest of the options.
  # If it exists, it is updated with the given options.
  #
  # Raises an exception if the record is invalid to ensure seed data is loaded correctly.
  #
  # Returns the record.
  def self.create_or_update(options = {})
    id = options.delete(:id)
    record = find_by_id(id) || new
    record.id = id
    record.attributes = options
    record.save!

    if block_given?
      children_array = []
      yield(children_array)
      children_array.each do |cat|
        cat.move_to_child_of(record)
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


#  def after_save
#    unless self.category_type_int.nil?
#      descendants.each do |a|
#        a.category_type_int = self.category_type_int
#        a.save!
#      end
#    end
#  end



end
