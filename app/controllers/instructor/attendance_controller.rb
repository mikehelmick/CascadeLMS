class Instructor::AttendanceController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab

  def index
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    load_periods
    @title = "Attendance | Class Periods for #{@course.title}"
    set_breadcrumb()
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
  
  def reopen
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    begin
      period = ClassPeriod.find(params[:id]) 
    rescue
      flash[:badnotice] = "Invalid period requested"
      redirect_to :action => 'index', :id => nil, :course => @course
      return
    end
    return unless period_in_class?( period, @course )
    
    period.gen_key
    period.open = true
    period.save
    
    redirect_to :action => 'index', :id => nil, :course => @course  
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
    @num_attending = 0
    
    @period.class_attendances.each do |att|
      @attendees[att.user_id] = true
      if att.correct_key
        @correct_key[att.user_id] = true
        @num_attending += 1
      end
    end
    
    @title = "Attendance on #{Date::MONTHNAMES[@period.created_at.mon]} #{@period.created_at.mday}, #{@period.created_at.year} for #{@course.title}"
    set_breadcrumb().text = 'View Class Attendance'
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
    
    @success = att.save
    
    render :layout => false
  end
  
  def mark_missing
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    return unless load_period(params[:id])
    student = User.find( params[:user].to_i ) 
    return unless student_in_course( @course, student)
    
    att = ClassAttendance.find(:first, :conditions => ["class_period_id = ? and course_id = ? and user_id = ?", @period.id, @course.id, student.id ] ) rescue att = nil
    
    @success = att.nil? || att.destroy()

    render :layout => false
  end
  
  def report
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    common_report

    @title = "Attendance report for #{@course.title}"
    set_breadcrumb().text = 'Report'
    render :layout => 'noright'
  end
  
  def export_csv
    return unless load_course( params[:course] )
    return unless attendance_enabled( @course )
    return unless ensure_course_instructor_on_assistant( @course, @user )
    
    common_report
    
    
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'inline; filename=gradebook.csv'
    
    render :layout => false
  end

  
  private

  def set_breadcrumb()
    @breadcrumb = Breadcrumb.for_course(@course, true)
    @breadcrumb.attendance = true
    return @breadcrumb
  end
  
  def common_report
    load_periods
    
    ## exclude instructors who are also students
    @exclude = Hash.new
    #@course.instructors.each do |inst|
    #  @exclude[inst.id] = true
    #end
    
    ## initialize attendance map
    @att_map = Hash.new
    @students = Array.new
    @course.students.each do |student|
      if @exclude[student.id].nil?
         @att_map[student.id] = Hash.new
         @students << student
      end
    end

    @period_attendance = Hash.new
    
    ## for each class period
    @periods.each do |period|
      @students.each do |student|
        @att_map[student.id][period.id] = false
      end
      
      period.class_attendances.each do |att|
        if att.correct_key
          if @exclude[att.user_id].nil?
            begin
              @att_map[att.user_id][period.id] = true 
              @period_attendance[period.id] = 0 if @period_attendance[period.id].nil?
              @period_attendance[period.id] = @period_attendance[period.id].next
            rescue
            end
          end
        end
      end
    end
  end
  
  def load_period( period )
    @period = ClassPeriod.find( period ) rescue @period = nil
    if @period.nil?
      flash[:badnotice] = "The requested class period couldn't be found."
      redirect_to :action => 'index', :course => @course, :id => nil
      return false
    end
    return true
  end
  
  def period_in_class?( period, course )
    if period.course_id != course.id
      flash[:badnotice] = "Invalid period requested"
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
