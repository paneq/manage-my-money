require 'validates_equality'

ActiveRecord::Base.class_eval do
  include ValidatesEquality
end
