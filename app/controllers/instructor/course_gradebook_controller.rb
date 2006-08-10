class Instructor::CourseGradebookController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
   before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
  end
  
  def settings
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    unless @course.gradebook
      @course.gradebook = Gradebook.new 
      @course.gradebook.save
    end
    @gradebook = @course.gradebook
  end
  
  def save_settings
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    @gradebook = @course.gradebook
    if @gradebook.update_attributes(params[:gradebook])
      flash[:notice] = 'Grade Book settings were successfully updated.'
      redirect_to :controller => '/instructor/course_gradebook', :course => @course
    else
      render :action => 'index'
    end
    
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
    @title = "Course Settings"
  end
  
  private :set_tab
  
end
