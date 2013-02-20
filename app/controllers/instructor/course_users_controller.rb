class Instructor::CourseUsersController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab

  layout 'application_right'
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    @show_images = false
    @show_images = true if params[:show_images]
    @showCRN = false

    @access_requests = Array.new
    @rejected_requests = Array.new
    @course.courses_users.each do |cu|
      # Find access requests that haven't been rejected.
      if (cu.propose_student && !cu.reject_propose_student) || (cu.propose_guest && !cu.reject_propose_guest)
        @access_requests << cu
      elsif (cu.reject_propose_student || cu.reject_propose_guest)
        @rejected_requests << cu.user
      end
      
    end
    # If there are any access requests - then clear the notifications
    if @access_requests.size > 0
      Notification.update_all("acknowledged=1", "user_id=#{@user.id} and course_id=#{@course.id} and proposal=1")
      @notificationCount = @user.notification_count
    end

    @breadcrumb = Breadcrumb.for_course(@course, true)
    @breadcrumb.text = 'Course Users'
    @breadcrumb.link = url_for(:action => 'index', :show_images => @show_images)
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

  def approve_proposal
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )

    cu = CoursesUser.find(params[:id])
    if cu.propose_student
      cu.course_student = true
    elsif cu.propose_guest
      cu.course_guest = true
    end
    # clear proposal fields
    cu.propose_student = false
    cu.reject_propose_student = false
    cu.propose_guest = false
    cu.reject_propose_guest = false

    if cu.save
      flash[:notice] = "Course access approved for #{cu.user.display_name}"
    else
      flash[:badnotice] = "There was an error approving this access request."
    end

    redirect_to :action => 'index', :id => nil, :course => @course
  end

  def reject_proposal
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )

    cu = CoursesUser.find(params[:id])
    if cu.propose_student
      cu.reject_propose_student = true
    end
    if cu.propose_guest
      cu.reject_propose_guest = true
    end
    cu.propose_student = false
    cu.propose_guest = false

    if cu.save
      flash[:notice] = "Course access rejected for #{cu.user.display_name}. This user will not be able to propose access again."
    else
      flash[:badnotice] = "There was an error rejecting this access request."
    end

    redirect_to :action => 'index', :id => nil, :course => @course
  end
  
  def deluser
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )

    @utype = params[:type]
    @course = Course.find(params[:course])
    @course.courses_users.each do |u|
      if u.user_id.to_i == params[:id].to_i
        #puts "found correct user: #{u.user}"
        if @utype.eql?('student')
           u.course_student = false
           u.dropped = true
        end 
        u.course_instructor = false if @utype.eql?('instructor')
        u.course_assistant = false if @utype.eql?('assistant')
        u.course_guest = false if @utype.eql?('guest')
        if u.any_user?
          # Un-subscribe this user from from the course feed
          unless @course.feed.nil?
            subscription = FeedSubscription.find(:first, :conditions => ["feed_id = ? and user_id = ?", @course.feed.id, u.user_id])
            subscription.destroy unless subscription.nil?
          end
          u.save
        else
          u.destroy
        end
        @course.save
      end
    end
    
    render :nothing => true
  end
  
  # This action is only for changing student CRNs.
  # if called w/ other types of user, no harm, no foul
  def change_student_crn
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    crn = Crn.find(params[:crn]) rescue crn = nil
    found = false
    found = true if params[:crn].eql?("0")
    @course.crns.each do |course_crn|
      found = found || course_crn.id = crn.id
    end    
    return unless found
    
    @course.courses_users.each do |u|
      if u.user_id.to_i == params[:id].to_i && u.course_student
        u.crn_id = params[:crn].to_i
        if u.save
          flash[:notice] = "Section assignment has been updated for student: #{u.user.display_name}"
        end
        @course.save
      end
    end
    
    redirect_to :action => 'index', :course => @course, :id => nil, :crn => nil
  end
  
  def adduser
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    @utype = params[:type]
    added = false
    @course.courses_users.each do |u|
      if u.user_id.to_i == params[:id].to_i
        if @utype.eql?('student')
          u.course_student = true 
          u.dropped = false
        end
        u.course_instructor = true if @utype.eql?('instructor')
        u.course_assistant = true if @utype.eql?('assistant')
        u.course_guest = true if @utype.eql?('guest')
        u.term_id = @course.term_id
        u.propose_student = false
        u.reject_propose_student = false
        u.propose_guest = false
        u.reject_propose_guest = false
        u.save
        @course.save
        @course.feed.subscribe_user(User.find(params[:id]), false)
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
      c.term_id = @course.term_id
      @course.courses_users << c
      @course.save 
      @course.feed.subscribe_user(user, false)  
    end
    
    @showCRN = false
    
    @users = @course.students_courses_users if @utype.eql?('student')
    @showCRN = true if @utype.eql?('student') &&  @course.crns.size > 1
    @users = @course.assistants if @utype.eql?('assistant')
    @users = @course.guests if @utype.eql?('guest')
    @users = @course.instructors if @utype.eql?('instructor')
    
    render :layout => false, :partial => 'userlist'
  end  
end
