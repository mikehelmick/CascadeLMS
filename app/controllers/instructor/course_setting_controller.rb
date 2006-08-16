class Instructor::CourseSettingController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_settings' )
    
    @course_settings = @course.course_setting
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }


  def update
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_settings' )
    return unless course_open( @course, :action => 'index' )
    
    @course_settings = @course.course_setting
    if @course_settings.update_attributes(params[:course_settings])
      flash[:notice] = 'Settings were successfully updated.'
      redirect_to :controller => '/instructor/index', :course => @course
    else
      render :action => 'index'
    end
  end

  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
    @title = "Course Settings"
  end
  
end
