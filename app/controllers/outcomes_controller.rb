class OutcomesController < ApplicationController
  before_filter :ensure_logged_in
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    load_outcome_numbers(@course)
    set_tab
  end

  private
  def set_tab
    @show_course_tabs = true
    @tab = "course_outcomes"
    @title = "Course Outcomes"
    @breadcrumb = Breadcrumb.new
    @breadcrumb.course = @course
    @breadcrumb.text = 'Course Outcomes'
  end
end
