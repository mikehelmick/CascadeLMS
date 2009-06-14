require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users

  # Replace this with your real tests.
  def test_invalid_with_empty_attributes
    user = User.new
    assert !user.valid?
    assert user.errors.invalid?(:uniqueid)
    assert user.errors.invalid?(:password)
    assert user.errors.invalid?(:first_name)
    assert user.errors.invalid?(:last_name)
    assert user.errors.invalid?(:email)
  end
  
  def test_invalid_email
    user = User.new
    user.email = 'invalid@address'
    assert !user.valid?
    assert user.errors.invalid?(:email)
  end
  
  def test_valid_email
    user = User.new
    user.email = 'valid@address.com'
    assert !user.valid?
    assert !user.errors.invalid?(:email)    
  end
  
  def test_display_name
    user = User.find(1)
    assert user.display_name.eql?("Test (T.U.) A. User")
    
    user2 = User.find(2)
    assert user2.display_name.eql?("Im A. Teacher")
  end
  
  def test_update_password
    user = User.find(1)
    user.update_password("Password1")
    assert user.save
    
    assert User.find(1).valid_password?("Password1")
  end
end
