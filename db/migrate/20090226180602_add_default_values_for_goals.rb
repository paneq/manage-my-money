class AddDefaultValuesForGoals < ActiveRecord::Migration
  def self.up
    change_column_default(:goals, :goal_type_int, 0)
    change_column_default(:goals, :goal_completion_condition_int, 0)
  end

  def self.down
    #ekhm...
    #Note from change_column_default help:
    #
    #
    # Sets a new default value for a column.  If you want to set the default
    # value to +NULL+, you are out of luck.  You need to
    # DatabaseStatements#execute the appropriate SQL statement yourself.
    # ===== Examples
    #  change_column_default(:suppliers, :qualification, 'new')
    #  change_column_default(:accounts, :authorized, 1)
    #
    #  
    #It isn't that important
  end
end
