require File.dirname(__FILE__) + '/../../test_helper'
require 'public/documents_controller'

# Re-raise errors caught by the controller.
class Public::DocumentsController; def rescue_action(e) raise e end; end

class Public::DocumentsControllerTest < ActionController::TestCase
  def setup
    @controller = Public::DocumentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
