require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/email_controller'

# Re-raise errors caught by the controller.
class Instructor::EmailController; def rescue_action(e) raise e end; end

class Instructor::EmailControllerTest < ActionController::TestCase
  def setup
    @controller = Instructor::EmailController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
