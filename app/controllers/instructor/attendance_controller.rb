class Instructor::AttendanceController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
 
  def index
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    load_periods
  end
  
  def open
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    load_periods
    
    if @current_period.nil?
      
      period = ClassPeriod.new
      period.course = @course
      period.open = true
      period.save
      
    else
      flash[:badnotice] = "You can't have two open class periods, you must close the open one first."
    end
    
    redirect_to :action => 'index'
  end
  
  def close
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    load_periods

    if @current_period.nil?
      flash[:notice] = "No class period to close."
    
    else
      @current_period.open = false
      @current_period.save   
      flash[:notice] = "Current period has been closed."
    end
    
    redirect_to :action => 'index'
  end
  
  def view
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    return unless load_period(params[:id])
    
    @attendees = Hash.new
    @correct_key = Hash.new
    
    @period.class_attendances.each do |att|
      @attendees[att.user_id] = true
      if att.correct_key
        @correct_key[att.user_id] = true
      end
    end
    
  end
  
  def mark_attending
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    return unless load_period(params[:id])
    student = User.find( params[:user].to_i ) 
    return unless student_in_course( @course, student)
    
    att = ClassAttendance.find(:first, :conditions => ["class_period_id = ? and course_id = ? and user_id = ?", @period.id, @course.id, student.id ] ) rescue att = nil
    if att.nil?
      att = ClassAttendance.new
      att.class_period = @period
      att.user = student
      att.course = @course
    end
    att.correct_key = true
    
    if att.save
      flash[:notice] = "Marked '#{student.display_name}' as attending."
    else
      flash[:badnotice] = "Attendance update for '#{student.display_name}' failed."
    end
    
    redirect_to :action => 'view', :id => @period, :user => nil, :course => @course
  end
  
  def mark_missing
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    return unless load_period(params[:id])
    student = User.find( params[:user].to_i ) 
    return unless student_in_course( @course, student)
    
    att = ClassAttendance.find(:first, :conditions => ["class_period_id = ? and course_id = ? and user_id = ?", @period.id, @course.id, student.id ] ) rescue att = nil
    
    if att.nil? || att.destroy()
      flash[:notice] = "Marked '#{student.display_name}' as not attending."
    else
      flash[:badnotice] = "Attendance update for '#{student.display_name}' failed."
    end
    
    redirect_to :action => 'view', :id => @period, :user => nil, :course => @course
  end
  
  
  private
  
  def load_period( period )
    @period = ClassPeriod.find( period ) rescue @period = nil
    if @period.nil?
      flash[:badnotice] = "The requested class period couldn't be found."
      redirect_to :action => 'index', :course => @course, :id => nil
      return false
    end
    return true
  end
  
  
  def attendance_enabled( course )
    unless course.course_setting.enable_attendance
      flash[:badnotice] = "Attendance is not enabled for this course."
      redirect_to :controller => '/instructor/index', :course => course
      return false
    end
    return true
  end
  
  def load_periods
    @periods = @course.class_periods
    
    @current_period = nil
    @periods.each do |i|
      @current_period = i if i.open  
    end
  end
  
  def set_tab
     @show_course_tabs = true
     @tab = "course_instructor"
  end

  def set_title
     @title = "Attendance - #{@course.title}"
  end
  
  
end