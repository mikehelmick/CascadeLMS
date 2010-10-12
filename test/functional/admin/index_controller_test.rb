require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/index_controller'

# Re-raise errors caught by the controller.
class Admin::IndexController; def rescue_action(e) raise e end; end

class Admin::IndexControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::IndexController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
