require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/course_admin_controller'

# Re-raise errors caught by the controller.
class Admin::CourseAdminController; def rescue_action(e) raise e end; end

class Admin::CourseAdminControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::CourseAdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

end
