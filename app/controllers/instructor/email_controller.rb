class Instructor::EmailController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
     return unless load_course( params[:course] )
     return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_send_email' )
    
     @email = ''
     @email_subject = "#{@course.title}"
     @users_hash = Hash.new
     @course.instructors.each { |u| @users_hash[u.id] = true }
     @course.assistants.each { |u| @users_hash[u.id] = true }
     @course.students.each { |u| @users_hash[u.id] = true }
     @course.guests.each { |u| @users_hash[u.id] = true }
    
    
     set_title
  end
  
  def send_email
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_send_email' )
    
    send_users = Array.new
    @users_hash = Hash.new
    @course.instructors.each do |user| 
      send_users << user.email if send_users.index(user.email).nil? 
      @users_hash[user.id] = true
    end
    
    add_users( send_users, @users_hash, @course.assistants, params )
    add_users( send_users, @users_hash, @course.students, params )
    add_users( send_users, @users_hash, @course.guests, params )
       
    if ( params[:email_body].nil? || params[:email_body].eql?('') ) 
      flash[:badnotice] = "Email body can not be empty."
      render :action => 'index'
      return 
    end
    
    Notifier::deliver_send_email( send_users, params[:email_body], params[:email_subject], @user )
   
    flash[:notice] = 'Email delivered to selected users.'    
    render :action => 'index'
  end
  
  def add_users( send_users, user_hash, users, params )
    users.each do |user| 
      if ( params["user_#{user.id}"] && params["user_#{user.id}"].to_i > 0 )
        send_users << user.email if send_users.index(user.email).nil? 
        user_hash[user.id] = true
      end
    end
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "Send Email - #{@course.title}"
  end
  
  private :set_tab, :set_title, :add_users
  
end