require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/course_setting_controller'

# Re-raise errors caught by the controller.
class Instructor::CourseSettingController; def rescue_action(e) raise e end; end

class Instructor::CourseSettingControllerTest < ActionController::TestCase
  fixtures :course_settings

  def setup
    @controller = Instructor::CourseSettingController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

end
