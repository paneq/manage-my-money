require 'test_helper'

class MemcachedTest < ActiveSupport::TestCase
  def test_memcached_write_and_read
    require_memcached
    assert_equal true, Rails.cache.write('key', '123456')
    assert_equal '123456', Rails.cache.read('key')
  end
end