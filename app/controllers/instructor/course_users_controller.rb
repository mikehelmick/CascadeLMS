class Instructor::CourseUsersController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
    @title = "Course Users"
  end
  
  def search
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    st = params[:searchterms].downcase
    if st.length >= 4
      sv = "%#{st}%"
      @users = User.find(:all, :conditions => ["LOWER(uniqueid) like ? or LOWER(first_name) like ? or LOWER(last_name) like ? or LOWER(preferred_name) like ?", sv, sv, sv, sv ], :order => "uniqueid asc")
    else
      @invalid = true
    end
  
    render :layout => false
  end
  
  def deluser
    @utype = params[:type]
    @course = Course.find(params[:course])
    @course.courses_users.each do |u|
      if u.user_id.to_i == params[:id].to_i
        #puts "found correct user: #{u.user}"
        u.course_student = false if @utype.eql?('student')
        u.course_instructor = false if @utype.eql?('instructor')
        u.course_assistant = false if @utype.eql?('assistant')
        u.course_guest = false if @utype.eql?('guest')
        if u.any_user?
          u.save
        else
          u.destroy
        end
        @course.save
      end
    end
    
    render :nothing => true
  end
  
  def adduser
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    @utype = params[:type]
    added = false
    @course.courses_users.each do |u|
      if u.user_id.to_i == params[:id].to_i
        u.course_student = true if @utype.eql?('student')
        u.course_instructor = true if @utype.eql?('instructor')
        u.course_assistant = true if @utype.eql?('assistant')
        u.course_guest = true if @utype.eql?('guest')
        u.save
        @course.save
        added = true
      end
    end
    
    unless added
      c = CoursesUser.new
      user = User.find(params[:id])
      c.course = @course
      c.user = user
      c.course_student = false
      c.course_student = true if @utype.eql?('student')
      c.course_instructor = true if @utype.eql?('instructor')
      c.course_assistant = true if @utype.eql?('assistant')
      c.course_guest = true if @utype.eql?('guest')  
      @course.courses_users << c
      @course.save   
    end
    
    @users = @course.students if @utype.eql?('student')
    @users = @course.assistants if @utype.eql?('assistant')
    @users = @course.guests if @utype.eql?('guest')
    @users = @course.instructors if @utype.eql?('instructor')
    
    render :layout => false, :partial => 'userlist'
  end
  
end
