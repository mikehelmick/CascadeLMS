require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/settings_controller'

# Re-raise errors caught by the controller.
class Admin::SettingsController; def rescue_action(e) raise e end; end

class Admin::SettingsControllerTest < ActionController::TestCase
  def setup
    @controller = Admin::SettingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

end
