require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/teams_controller'

# Re-raise errors caught by the controller.
class Instructor::TeamsController; def rescue_action(e) raise e end; end

class Instructor::TeamsControllerTest < ActionController::TestCase
  def setup
    @controller = Instructor::TeamsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
