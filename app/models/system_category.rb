# == Schema Information
# Schema version: 20090313212009
#
# Table name: system_categories
#
#  name       :string(255)   not null
#  parent_id  :integer       
#  lft        :integer       
#  rgt        :integer       
#  created_at :datetime      
#  updated_at :datetime      
#

class SystemCategory < ActiveRecord::Base

  has_and_belongs_to_many :categories

  acts_as_nested_set

  validates_presence_of :name

end
