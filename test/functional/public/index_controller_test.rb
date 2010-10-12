require File.dirname(__FILE__) + '/../../test_helper'
require 'public/index_controller'

# Re-raise errors caught by the controller.
class Public::IndexController; def rescue_action(e) raise e end; end

class Public::IndexControllerTest < ActionController::TestCase
  def setup
    @controller = Public::IndexController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
