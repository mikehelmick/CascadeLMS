require File.dirname(__FILE__) + '/../../test_helper'
require 'public/blog_controller'

# Re-raise errors caught by the controller.
class Public::BlogController; def rescue_action(e) raise e end; end

class Public::BlogControllerTest < Test::Unit::TestCase
  def setup
    @controller = Public::BlogController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
