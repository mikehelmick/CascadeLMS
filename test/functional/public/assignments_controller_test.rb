require File.dirname(__FILE__) + '/../../test_helper'
require 'public/assignments_controller'

# Re-raise errors caught by the controller.
class Public::AssignmentsController; def rescue_action(e) raise e end; end

class Public::AssignmentsControllerTest < ActiveSupport::TestCase
  def setup
    @controller = Public::AssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
