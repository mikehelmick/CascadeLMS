require File.dirname(__FILE__) + '/../test_helper'
require 'attendance_controller'

# Re-raise errors caught by the controller.
class AttendanceController; def rescue_action(e) raise e end; end

class AttendanceControllerTest < ActiveSupport::TestCase
  def setup
    @controller = AttendanceController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
