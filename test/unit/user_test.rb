require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users

  def test_invalid_with_empty_attributes
    user = User.new
    assert !user.valid?
    assert user.errors.invalid?(:name)
    assert user.errors.invalid?(:email)
  end

  def test_name_uniqness
  
    user = User.new(:name => 'john',
                    :email => 'jp@wp.pl',
                    :password =>'mypass',
                    :password_confirmation => 'mypass')
                    
    assert !user.save
    assert_equal 'User with that name already exists', user.errors.on(:name)
  end

  def password_validation
    user = User.new(:name => 'robert_pankowecki',
                    :email => 'rp@wp.pl',
                    :password =>'mypass',
                    :password_confirmation => 'another_pass')
                    
    assert !user.save
    assert_equal 'Given passwords was not the same', user.errors.on(:password)
  end

end
