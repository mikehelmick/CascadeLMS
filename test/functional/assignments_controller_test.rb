require File.dirname(__FILE__) + '/../test_helper'
require 'assignments_controller'

# Re-raise errors caught by the controller.
class AssignmentsController; def rescue_action(e) raise e end; end

class AssignmentsControllerTest < ActionController::TestCase
  def setup
    @controller = AssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
end
