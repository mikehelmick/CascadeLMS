require File.dirname(__FILE__) + '/../test_helper'
require 'blog_controller'

# Re-raise errors caught by the controller.
class BlogController; def rescue_action(e) raise e end; end

class BlogControllerTest < Test::Unit::TestCase
  def setup
    @controller = BlogController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
