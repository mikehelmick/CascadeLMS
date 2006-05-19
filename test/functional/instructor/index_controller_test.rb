require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/index_controller'

# Re-raise errors caught by the controller.
class Instructor::IndexController; def rescue_action(e) raise e end; end

class Instructor::IndexControllerTest < Test::Unit::TestCase
  def setup
    @controller = Instructor::IndexController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
