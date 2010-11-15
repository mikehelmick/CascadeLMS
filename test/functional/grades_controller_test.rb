require File.dirname(__FILE__) + '/../test_helper'
require 'grades_controller'

# Re-raise errors caught by the controller.
class GradesController; def rescue_action(e) raise e end; end

class GradesControllerTest < ActionController::TestCase
  def setup
    @controller = GradesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
