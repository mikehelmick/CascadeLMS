require File.dirname(__FILE__) + '/../test_helper'
require 'overview_controller'

# Re-raise errors caught by the controller.
class OverviewController; def rescue_action(e) raise e end; end

class OverviewControllerTest < ActionController::TestCase
  def setup
    @controller = OverviewController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
