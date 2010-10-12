require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/quiz_controller'

# Re-raise errors caught by the controller.
class Instructor::QuizController; def rescue_action(e) raise e end; end

class Instructor::QuizControllerTest < ActionController::TestCase
  def setup
    @controller = Instructor::QuizController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
