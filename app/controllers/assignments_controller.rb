class AssignmentsController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab

  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
 
    set_title
  end
  
  def view
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    @now = Time.now
    set_title
  end

  def assignment_available( assignment )
    unless assignment.open_date <= Time.now
      flash[:badnotice] = "The requisted assignment is not yet available."
      redirect_to :action => 'index'
      return false
    end
    true
  end

  def assignment_in_course( assignment, course )
    unless assignment.course_id == course.id 
      flash[:badnotice] = "The requested assignment could not be found."
      redirect_to :action => 'index'
      return false
    end
    true
  end

  def set_tab
    @show_course_tabs = true
    @tab = "course_assignments"
    @title = "Course Assignments"
  end

  def set_title
    @title = "#{@course.title} (Course Assignments)"
    @title = "#{@assignment.title} - #{@course.title}" unless @assignment.nil?
  end
  
  private :set_tab, :set_title, :assignment_in_course, :assignment_available
  
end
