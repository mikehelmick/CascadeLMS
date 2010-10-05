require File.dirname(__FILE__) + '/../../test_helper'
require 'courses/overview_controller'

# Re-raise errors caught by the controller.
class Courses::OverviewController; def rescue_action(e) raise e end; end

class Courses::OverviewControllerTest < ActiveSupport::TestCase
  def setup
    @controller = Courses::OverviewController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
