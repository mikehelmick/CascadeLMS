require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/course_settings_controller'

# Re-raise errors caught by the controller.
class Instructor::CourseSettingsController; def rescue_action(e) raise e end; end

class Instructor::CourseSettingsControllerTest < Test::Unit::TestCase
  fixtures :course_settings

  def setup
    @controller = Instructor::CourseSettingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:course_settings)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:course_settings)
    assert assigns(:course_settings).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:course_settings)
  end

  def test_create
    num_course_settings = CourseSettings.count

    post :create, :course_settings => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_course_settings + 1, CourseSettings.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:course_settings)
    assert assigns(:course_settings).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil CourseSettings.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      CourseSettings.find(1)
    }
  end
end
