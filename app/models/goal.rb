# == Schema Information
# Schema version: 20081110145518
#
# Table name: goals
#
#  id                            :integer       not null, primary key
#  description                   :string(255)   
#  include_subcategories         :boolean       
#  period_type_val               :integer       
#  goal_type_val                 :integer       
#  goal_completion_condition_val :integer       
#  category_id                   :integer       not null
#  created_at                    :datetime      
#  updated_at                    :datetime      
#

require 'hash_enums'
class Goal < ActiveRecord::Base
  extend HashEnums
  belongs_to :category

  define_enum :period_type, {:infinite => 0,:monthly => 1}
  define_enum :goal_type, {:percent=>0, :value=>1}
  define_enum :goal_completion_condition,{:maximize=>0, :minimize=>1}

end

