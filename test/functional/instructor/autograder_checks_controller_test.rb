require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/autograder_checks_controller'

# Re-raise errors caught by the controller.
class Instructor::AutograderChecksController; def rescue_action(e) raise e end; end

class Instructor::AutograderChecksControllerTest < ActiveSupport::TestCase
  def setup
    @controller = Instructor::AutograderChecksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
