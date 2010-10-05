require File.dirname(__FILE__) + '/../../test_helper'
require 'instructor/assignment_io_checks_controller'

# Re-raise errors caught by the controller.
class Instructor::AssignmentIoChecksController; def rescue_action(e) raise e end; end

class Instructor::AssignmentIoChecksControllerTest < ActiveSupport::TestCase
  fixtures :io_checks

  def setup
    @controller = Instructor::AssignmentIoChecksController.new
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

    assert_not_nil assigns(:io_checks)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:io_check)
    assert assigns(:io_check).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:io_check)
  end

  def test_create
    num_io_checks = IoCheck.count

    post :create, :io_check => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_io_checks + 1, IoCheck.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:io_check)
    assert assigns(:io_check).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil IoCheck.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      IoCheck.find(1)
    }
  end
end
