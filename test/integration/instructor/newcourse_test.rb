require 'test_helper'

class Instructor::NewcourseTest < ActionController::IntegrationTest
  fixtures :users, :terms, :settings

  test "login and change term on new course page" do
    login(users(:instructor).uniqueid)

    get '/instructor/newcourse'
    assert_response :success
    assert_select "input[id=term][value=#{terms(:fall).id}]", 1

    post '/instructor/newcourse/change_term', :id => terms(:spring).id
    assert_response :success
    assert_select "input[id=term][value=#{terms(:spring).id}]", 1
  end
end
