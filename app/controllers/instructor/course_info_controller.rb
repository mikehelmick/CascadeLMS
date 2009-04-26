class Instructor::CourseInfoController < Instructor::InstructorBase
 
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_information' )
    
    @course_information = @course.course_information
    if @course_information.nil?
      @course_information = CourseInformation.new
    end
    @courseo = @course
  end
  
  def update
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_information' )
    return unless course_open( @course, :action => 'index' )
    
    if @course.course_information.nil?
      @course.course_information = CourseInformation.new
      @course.course_information.course = @course
    end
    
    if @course.update_attributes(params[:courseo]) && @course.course_information.update_attributes(params[:course_information])
      
      flash[:notice] = "Course information has been updated."
      redirect_to :controller => '/instructor/index', :course =>  params[:course]
    else
      @courseo = @course
      @course_information = @course.course_information
      render :action => 'index'
    end
  end
  
  def merge
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_information' )
    return unless course_open( @course, :action => 'index' )
   
    other = Course.find(params[:id])
    
    #begin
      @course.merge(other,@app['external_dir'])
      
      flash[:notice] = "Courses have been merged successfully."
      redirect_to :action => 'index', :id => @course
    #rescue
    #  flash[:badnotice] = "There was an error merging the courses"
    #  redirect_to :action => 'index', :id => @course
    #end
  end
  
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
    @title = "Course Information"
  end
  
end
