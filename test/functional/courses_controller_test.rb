require File.dirname(__FILE__) + '/../test_helper'
require 'courses_controller'

# Re-raise errors caught by the controller.
class CoursesController; def rescue_action(e) raise e end; end

class CoursesControllerTest < Test::Unit::TestCase
  def setup
    @controller = CoursesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
