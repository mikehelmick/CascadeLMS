require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/course_gradebook_controller'

# Re-raise errors caught by the controller.
class Instructor::CourseGradebookController; def rescue_action(e) raise e end; end

class Instructor::CourseGradebookControllerTest < Test::Unit::TestCase
  def setup
    @controller = Instructor::CourseGradebookController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
