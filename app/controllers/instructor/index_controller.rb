class Instructor::IndexController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab

  layout 'application_right'
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_on_assistant( @course, @user )
  
    set_title
  end
  
  def toggle_open
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    @course.toggle_open
    @course.save
    
    redirect_to :action => 'index'
  end
  
  def toggle_public
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    @course.public = ! @course.public
    @course.save
    
    redirect_to :action => 'index'
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "Course Instructor - #{@course.title}"
  end

  
end
