require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/course_users_controller'

# Re-raise errors caught by the controller.
class Instructor::CourseUsersController; def rescue_action(e) raise e end; end

class Instructor::CourseUsersControllerTest < Test::Unit::TestCase
  def setup
    @controller = Instructor::CourseUsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
