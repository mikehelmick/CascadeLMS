class Instructor::EmailController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
     return unless load_course( params[:course] )
     return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_send_email' )
    
     
    
     set_title
  end
  
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "Send Email - #{@course.title}"
  end
  
  private :set_tab, :set_title
  
end