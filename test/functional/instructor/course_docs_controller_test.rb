require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/course_docs_controller'

# Re-raise errors caught by the controller.
class Instructor::CourseDocsController; def rescue_action(e) raise e end; end

class Instructor::CourseDocsControllerTest < ActionController::TestCase
  fixtures :documents

  def setup
    @controller = Instructor::CourseDocsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

end
