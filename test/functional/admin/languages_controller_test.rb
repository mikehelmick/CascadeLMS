require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/languages_controller'

# Re-raise errors caught by the controller.
class Admin::LanguagesController; def rescue_action(e) raise e end; end

class Admin::LanguagesControllerTest < ActiveSupport::TestCase
  fixtures :programming_languages

  def setup
    @controller = Admin::LanguagesController.new
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

    assert_not_nil assigns(:programming_languages)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:programming_language)
    assert assigns(:programming_language).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:programming_language)
  end

  def test_create
    num_programming_languages = ProgrammingLanguage.count

    post :create, :programming_language => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_programming_languages + 1, ProgrammingLanguage.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:programming_language)
    assert assigns(:programming_language).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil ProgrammingLanguage.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ProgrammingLanguage.find(1)
    }
  end
end
