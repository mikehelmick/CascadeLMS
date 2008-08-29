class Instructor::AutograderChecksController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index 
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :controller => '/instructor/index', :action => 'index', :course => @course )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )
    
    
    
    set_title
  end
  
end
