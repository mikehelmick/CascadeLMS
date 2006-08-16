require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/turnins_controller'

# Re-raise errors caught by the controller.
class Instructor::TurninsController; def rescue_action(e) raise e end; end

class Instructor::TurninsControllerTest < Test::Unit::TestCase
  def setup
    @controller = Instructor::TurninsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
