require 'test_helper'
require 'hash'

class HashTest < ActiveSupport::TestCase

  def test_pass
    h = {:one => 1}
    assert_equal h, {:one => 1, :two => 2, :three => 3}.pass(:one)

    hwia = HashWithIndifferentAccess.new
    hwia[:one] = 1
    hwia[:two] = 2
    hwia['three'] = 3
    hwia['four'] = 4
    hwia[5] = 5
    hwia[6] = 6

    passed = hwia.pass(:one, 'three', 5)
    assert_equal 1, passed[:one]
    assert_equal 1, passed['one']

    assert_equal 3, passed[:three]
    assert_equal 3, passed['three']

    assert_equal 5, passed[5]

    assert_nil passed[:two]
    assert_nil passed['two']

    assert_nil passed[:four]
    assert_nil passed['four']

    assert_nil passed[6]
  end


  def test_block
    h = {:one => 1, :two => 2}
    assert_equal h, {:one => 1, :two => 2, :three => 3}.block(:three)

    hwia = HashWithIndifferentAccess.new
    hwia[:one] = 1
    hwia[:two] = 2
    hwia['three'] = 3
    hwia['four'] = 4
    hwia[5] = 5
    hwia[6] = 6

    blocked = hwia.block(:two, 'four', 6)
    assert_equal 1, blocked[:one]
    assert_equal 1, blocked['one']

    assert_equal 3, blocked[:three]
    assert_equal 3, blocked['three']

    assert_equal 5, blocked[5]

    assert_nil blocked[:two]
    assert_nil blocked['two']

    assert_nil blocked[:four]
    assert_nil blocked['four']

    assert_nil blocked[6]
  end

end