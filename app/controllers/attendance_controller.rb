class AttendanceController < ApplicationController

  before_filter :ensure_logged_in
  before_filter :set_tab

  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless attendance_enabled( @course )
 
    load_periods
 
    @attendance = ClassAttendance.find(:all, :conditions => ["course_id = ? and user_id = ?", @course.id, @user.id], :order => "id asc")
 
    @attending_current = false
    unless @current_period.nil?
      @attendance.each do |ca|
        if ca.class_period_id == @current_period.id
          @attending_current = true if ca.correct_key
        end
      end
    end
    
    @class_matrix = Hash.new
    @attendance.each do |att|
      @class_matrix[att.class_period_id.to_s] = att
    end
    
    
 
    set_title
  end
  
  def record_attendance
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless attendance_enabled( @course )
    
    load_periods
    if @current_period.nil?
      flash[:badnotice] = "There is no open class period to record your attendance for."
      redirect_to :action => 'index', :course => @course
      return
    end
    
    if params[:key].nil?
      flash[:badnotice] = "You must enter an attendance key.  The attendance key is provided by your instructor."
      redirect_to :action => 'index', :course => @course
      return
    end
    
    attendance = ClassAttendance.find(:first, :conditions => ["class_period_id = ? and user_id = ?", @current_period.id, @user.id] )
    
    if attendance.nil? || !attendance.correct_key
      if attendance.nil?
        attendance = ClassAttendance.new
        attendance.course = @course
        attendance.class_period = @current_period
        attendance.user = @user
      end
      attendance.correct_key = params[:key].upcase.eql?( @current_period.key )
        
      if attendance.save
        if attendance.correct_key
          flash[:notice] = "Your attendance has been recorded."
        else
          flash[:badnotice] = "Incorrect key for this class period, please re-enter."
        end
      else
        flash[:badnotice] = "There was an error recording your attendance, please try again."
      end
        
    else 
      flash[:notice] = "Your attendance was already recorded." 
    end
    redirect_to :action => 'index', :course => @course

  end
  
  private
  
  def attendance_enabled( course )
    unless course.course_setting.enable_attendance
      flash[:badnotice] = "Attendance is not enabled for this course."
      redirect_to :controller => '/overview', :course => course
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
  
  def set_title
    @title = "Attendance for #{@course.title}"
  end
  
  def set_tab
    @tab = 'course_attendance'
    @show_course_tabs = true
  end
  
end
