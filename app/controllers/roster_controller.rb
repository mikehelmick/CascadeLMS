class RosterController < ApplicationController
  before_filter :ensure_logged_in
  before_filter :set_tab

  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )

    @instructors = @course.instructors
    @students = @course.students

    @breadcrumb = Breadcrumb.for_course(@course)
    @breadcrumb.roster = true
  end

  private
  def set_tab
    @show_course_tabs = true
    @tab = "course_roster"
    @title = "Course Roster"
  end
end
