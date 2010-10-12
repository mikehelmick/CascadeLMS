require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/user_admin_controller'

# Re-raise errors caught by the controller.
class Admin::UserAdminController; def rescue_action(e) raise e end; end

class Admin::UserAdminControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::UserAdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
