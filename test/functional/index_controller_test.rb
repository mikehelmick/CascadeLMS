require File.dirname(__FILE__) + '/../test_helper'
require 'index_controller'

# Re-raise errors caught by the controller.
class IndexController; def rescue_action(e) raise e end; end

class IndexControllerTest < ActionController::TestCase
  def setup
    @controller = IndexController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index_load
    get :index
    assert_response :success
  end

  def test_register_load
    get :register
    assert_response :success
  end

  def test_register_account
    username = 'moose1'
    post :create,
        :new_user => {:uniqueid => username, :first_name => 'Bullwinkle', :middle_name => 'J',
                      :last_name => 'Moose', :email => 'bmoose@cascadelms.org'}
    assert_redirected_to :controller => 'index', :action => 'index'

    user = User.find(:first, :conditions => ['uniqueid = ?', username])
    assert_not_nil(user, "Created user could not be found")
  end

  def test_login
    user = create_test_user('moose1', 'Bullwinkle', 'Moose', 'bmoose@cascadelms.org', 'rocket')

    post :login, :user => {:uniqueid => 'moose1', :password => 'rocket'}
    assert_redirected_to :controller => 'home'
  end

  def test_forgot_load
    get :forgot
    assert_response :success
  end

  def test_forgot_send
    user = create_student('student')
    user.forgot_token = '42'
    user.save

    post :send_forgot, :uniqueid => 'student'
    assert_redirected_to :action => 'index'

    user = User.find(user.id)
    # If the password rest is in progress, the forgot token will be filled in.
    assert_not_equal(42, user.forgot_token)
  end
end
