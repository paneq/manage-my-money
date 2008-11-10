# == Schema Information
# Schema version: 20081110145518
#
# Table name: goals
#
#  id                        :integer       not null, primary key
#  description               :string(255)   
#  include_subcategories     :boolean       
#  period_type               :integer       
#  goal_type                 :integer       
#  goal_completion_condition :integer       
#  created_at                :datetime      
#  updated_at                :datetime      
#

class Goal < ActiveRecord::Base
end
