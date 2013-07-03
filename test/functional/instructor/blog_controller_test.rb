require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/blog_controller'

# Re-raise errors caught by the controller.
class Instructor::BlogController; def rescue_action(e) raise e end; end

class Instructor::BlogControllerTest < ActionController::TestCase
  fixtures :posts

  def setup
    @controller = Instructor::BlogController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

end
