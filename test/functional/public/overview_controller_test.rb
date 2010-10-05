require File.dirname(__FILE__) + '/../../test_helper'
require 'public/overview_controller'

# Re-raise errors caught by the controller.
class Public::OverviewController; def rescue_action(e) raise e end; end

class Public::OverviewControllerTest < ActiveSupport::TestCase
  def setup
    @controller = Public::OverviewController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
