require File.dirname(__FILE__) + '/../test_helper'
require 'turnins_controller'

# Re-raise errors caught by the controller.
class TurninsController; def rescue_action(e) raise e end; end

class TurninsControllerTest < ActiveSupport::TestCase
  def setup
    @controller = TurninsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
