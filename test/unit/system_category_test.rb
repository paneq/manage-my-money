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

  test "should save children using create_or_update" do

    sc(:id => 1,
      :name => 'one',
      :description => '',
      :category_type => :ASSET) do |c|
      c << sc(:id => 2,
        :name => 'two',
        :description => '')
      c << sc(:id => 3,
        :name => 'three',
        :description => '') do |c|
        c << sc(:id => 4,
          :name => 'four')
      end
    end

    assert_equal 4, SystemCategory.count
    SystemCategory.all.each do |cat|
      assert_equal :ASSET, cat.category_type
    end

    one = SystemCategory.find(1)
    two = SystemCategory.find(2)
    three = SystemCategory.find(3)
    four = SystemCategory.find(4)

    assert_equal [2,3,4], one.descendants.map(&:id).sort
    assert_equal [], two.descendants.map(&:id).sort
    assert_equal [4], three.descendants.map(&:id).sort
    assert_equal [], four.descendants.map(&:id).sort
    assert_equal [1,3], four.ancestors.map(&:id).sort

  end

  test "should update children using create_or_update" do

    #first save
    sc(:id => 1,
      :name => 'one',
      :description => '',
      :category_type => :ASSET) do |child|
      child << sc(:id => 2,
        :name => 'two',
        :description => '')
      child << sc(:id => 4,
        :name => 'four',
        :description => '')
      end

    #update
    sc(:id => 1,
      :name => 'one_updated',
      :description => '',
      :category_type => :ASSET) do |child|
      child << sc(:id => 2,
        :name => 'two_updated',
        :description => '')
      child << sc(:id => 3,
        :name => 'three',
        :description => '')
      end

    one = SystemCategory.find(1)
    two = SystemCategory.find(2)
    three = SystemCategory.find(3)
    four = SystemCategory.find(4)

    assert_equal [2,3,4], one.descendants.map(&:id).sort
    assert_equal 'one_updated', one.name
    assert_equal [], two.descendants.map(&:id).sort
    assert_equal 'two_updated', two.name

    assert_not_nil three
    assert_not_nil four #notice: current specification dont allow deleting children, so four is still in db

  end




  private
  
  def sc(options, &children)
    SystemCategory.create_or_update(options, &children)
  end


end
