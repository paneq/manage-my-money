require File.dirname(__FILE__) + '/test_helper'

class ValidatesEqualityTest < ActiveSupport::TestCase

  class User < ActiveRecord::Base
    has_many :categories
    has_many :transfers
    has_many :transfer_items, :through => :transfers
  end

  
  class Category < ActiveRecord::Base
    has_many :transfers
    has_many :transfer_items
    belongs_to :user
  end


  class Transfer < ActiveRecord::Base
    belongs_to :category
    has_many :transfer_items
    has_many :categories, :through => :transfer_items
    belongs_to :user

    validates_user_id [:transfer_items, :category] 
    validates_user_id :category, :allow_nil => true
    validates_user_id [:transfer_items, :tags, :category], :raise_nil_in_chain => true
  end


  class TransferItem < ActiveRecord::Base
    belongs_to :category
    has_many :tags
  end


  class Tag < ActiveRecord::Base
    belongs_to :transfer_item
    belongs_to :category
  end

  def setup
    @rupert = User.new(:name => 'rupert')
    @rupert.save!

    @sejtenik = User.new(:name => 'sejtenik')
    @sejtenik.save!

    @rc1 = Category.new(:name => 'r1', :user => @rupert)
    @rc1.save!

    @rc2 = Category.new(:name => 'r2', :user => @rupert)
    @rc2.save!

    @sc1 = Category.new(:name => 's1', :user => @sejtenik)
    @sc1.save!

    @sc2 = Category.new(:name => 's2', :user => @sejtenik)
    @sc2.save!

    @nobody = Category.new(:name => 'nobody category')
    @nobody.save!
  end


  test "valid transfers" do
    t = Transfer.new(:user => @rupert, :category => @rc1)
    t.transfer_items.build(:category => @rc1)
    t.transfer_items.build(:category => @rc2)
    t.transfer_items.first.tags.build(:category => @rc1)
    t.transfer_items.first.tags.build(:category => @rc2)
    assert t.valid?

    t = Transfer.new(:user => @rupert, :category => @nobody)
    t.transfer_items.build(:category => @rc1)
    t.transfer_items.build(:category => @rc2)
    assert t.valid?

  end

  test "invalid transfers" do

    t = Transfer.new(:user => @rupert, :category => @sc1)
    assert_invalid(t)
    
    t = Transfer.new(:user => @rupert, :category => @rc1)
    t.transfer_items.build(:category => @sc1)
    assert_invalid(t)

    t = Transfer.new(:user => @rupert, :category => @nobody)
    t.transfer_items.build(:category => @sc1)
    assert_invalid(t)

    t = Transfer.new(:user => @rupert, :category => @rc1)
    t.transfer_items.build(:category => @nobody)
    assert_invalid(t)

    t = Transfer.new(:user => @rupert, :category => @rc2)
    t.transfer_items.build(:category => @rc1)
    t.transfer_items.first.tags.build(:category => @nobody)
    assert_invalid(t)
  end


  test "raise nil" do
    assert_raise(RuntimeError) do
      t = Transfer.new(:user => @rupert, :category => @rc2)
      t.transfer_items.build(:category => @rc2)
      t.transfer_items.first.tags.build(:category => nil)
      t.valid?
    end

    assert_nothing_raised(RuntimeError) do
      t = Transfer.new(:user => @rupert, :category => @rc2)
      t.transfer_items.build(:category => @rc2)
      t.transfer_items.first.tags.build(:category => @sc1)
      assert_invalid(t)

      t = Transfer.new(:user => @rupert, :category => @rc2)
      t.transfer_items.build(:category => @rc2)
      t.transfer_items.first.tags.build(:category => @rc1)
      assert t.valid?
    end
  end


  def assert_invalid(transfer)
    assert !transfer.valid?
    assert !transfer.errors.on(:user_id).empty?
  end

end
