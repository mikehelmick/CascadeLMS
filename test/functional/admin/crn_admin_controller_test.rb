require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/crn_admin_controller'

# Re-raise errors caught by the controller.
class Admin::CrnAdminController; def rescue_action(e) raise e end; end

class Admin::CrnAdminControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::CrnAdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

end
