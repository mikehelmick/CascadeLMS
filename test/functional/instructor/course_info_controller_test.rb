require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/course_info_controller'

# Re-raise errors caught by the controller.
class Instructor::CourseInfoController; def rescue_action(e) raise e end; end

class Instructor::CourseInfoControllerTest < ActionController::TestCase
  def setup
    @controller = Instructor::CourseInfoController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
