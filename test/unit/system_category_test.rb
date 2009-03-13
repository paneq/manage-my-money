require 'test_helper'

class SystemCategoryTest < ActiveSupport::TestCase
  
  def setup
    save_jarek
  end
  
  test "save with parent" do
    e = SystemCategory.create :name => 'Expenses'

    s = SystemCategory.create :name => 'Food'

    s.move_to_child_of e

    e.save!
    s.save!

    assert_equal 2, SystemCategory.all.count

    assert e.id, s.parent.id

  end
end
