require 'BasicAuthentication'
require 'LdapAuthentication'
require 'yaml'
require 'MyString'

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  
  layout 'application'
  
  before_filter :app_config, :browser_check
  after_filter :pull_msg
  
  @@auth_locations = ['REDIRECT_REDIRECT_X_HTTP_AUTHORIZATION',
                      'REDIRECT_X_HTTP_AUTHORIZATION',
                      'X-HTTP_AUTHORIZATION', 'HTTP_AUTHORIZATION',
                      'Authorization','AUTHORIZATION']                      
     
  @@app = nil            
  @@external_dir = nil            
                    
  def browser_check
    if request.env['HTTP_USER_AGENT'] && request.env['HTTP_USER_AGENT'].include?('MSIE')
      if !cookies[:ie_override].nil? && cookies[:ie_override].eql?( true.to_s )
        return true
      else
        if controller_name.eql?("browser")
          return true
        else
          redirect_to :controller => '/browser', :action => 'index'
          return false
        end
      end
    end
  end
  
  def session_valid?
     creation_time = session[:creation_time] || Time.now
     if !session[:expiry_time].nil? and session[:expiry_time] < Time.now
        # Session has expired. Clear the current session.
        reset_session    
        return false
     end

     # Assign a new expiry time, whether the session has expired or not.
     session[:expiry_time] = (@app['session_limit'].to_i).seconds.from_now

     return true
  end
  
  def pull_msg
    if session[:user] && session[:user].notice
      flash[:notice] = "#{flash[:notice]} #{session[:user].notice}"
      session[:user].notice = nil
    end
  end
  
  
  def ApplicationController.external_dir
    ApplicationController.app
    @@external_dir
  end
  
  def ApplicationController.root_dir
    return RAILS_ROOT
  end
  
  def ApplicationController.app
    if @@app.nil?
      @@app = YAML.load( File.open("#{RAILS_ROOT}/config/defaults.yml") )
 		  @@external_dir ||= @@app['external_dir']
 		end
 		return @@app
  end

  def app_config
 		@app ||= YAML.load( File.open("#{RAILS_ROOT}/config/defaults.yml") )
 	end
 	
 	def ensure_instructor
    unless session[:user].instructor?
      flash[:badnotice] = "You do not have the rights to view the requested page."
      redirect_to :controller => '/home'
      return false
    end
    return true
  end
  
  def ensure_admin
    unless session[:user].admin? || (!@user.nil? && @user.admin?)
      flash[:badnotice] = "You do not have the rights to view the requested page."
      redirect_to :controller => '/home'
      return false
    end
    return true
  end
 	
 	def boolean_to_text( boolean )
 	  if boolean
 	    "Yes"
    else
      "No"
    end
  end
  
  def disabled_text
    if course.open
      ''
    else
      'disabled="disabled"'
    end
  end
  
  def course_open( course, redirect_info = {} )
    unless course.open
      flash[:badnotice] = "The requested action can not be performed, since the course is in archive status."
      redirect_to redirect_info
      return false
    end
    return true
  end
 	
 	def ensure_logged_in
 	  redirect_uri = "#{request.protocol()}#{request.host()}#{request.port_string}#{request.request_uri()}"
 	
 	  if session[:user].nil?
 	    flash[:notice] = "Please log in before proceeding."
 	    session[:post_login] = redirect_uri
 	    redirect_to :controller => '/index'
 	    return false
    end
    
    if !session_valid?
      redirect_to :controller => '/index', :action => 'expired'
      session[:post_login] = redirect_uri
      
      return false
    end
    
    # duplicate user - to keep session down
    @user = User.find(session[:user].id)
    return true
  end
  
  def ensure_course_instructor( course, user )
    user.courses_users.each do |cu|
      if cu.course_id == course.id
        if cu.course_instructor
          return true
        end
      end  
    end
    flash[:badnotice] = "You are not authorized to perform that action."
    redirect_to :controller => '/overview', :course => course.id
    return false    
  end
  
  def course_is_public( course )
    unless course.public
      flash[:badnotice] = "The selected course is not available to the public."
      redirect_to :controller => '/public'
    end
    return true
  end
  
  def allowed_to_see_course( course, user, redirect = true)
    user.courses_users.each do |cu|
      if cu.course_id == course.id
        if cu.course_student || cu.course_assistant || cu.course_instructor || cu.course_guest
          return true
        end
      end  
    end
    flash[:badnotice] = "You are not authorized to view the requested course."
    redirect_to :controller => '/home' if redirect
    return false
  end
  
  def student_in_course( course, student )
    if ! student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested, the student is not enrolled in this course."
      redirect_to :action => 'index'
      return false
    end
    true
  end
  
  def assignment_in_course( assignment, course, redirect = true )
    unless assignment.course_id == course.id 
      flash[:badnotice] = "The requested assignment could not be found."
      redirect_to :controller => 'assignments', :action => 'index', :course => @course if redirect
      return false
    end
    true
  end
  
  def assignment_has_journals( assignment )
    unless assignment.enable_journal
      flash[:badnotice] = "The selected assignment does not have a journal requirement."
      redirect_to :controller => 'assignments', :action => 'view', :id => assignment.id, :course => @course, :assignment => nil
      return false
    end
    true
  end
  
  def load_course( course_id, redirect = true )
    begin
      @course = Course.find( course_id )
    rescue
      flash[:badnotice] = "Requested course could not be found."
      redirect_to :controller => '/home' if redirect
      return false
    end
  end
  
  def set_highlight( dom_id )
    flash[:highlight] = dom_id
  end
  
  def authenticate( user, redirect = true )
    auth = BasicAuthentication.new()
    auth = LdapAuthentication.new( @app ) if @app['authtype'].downcase.eql?('ldap')
    
    begin
      @user = auth.authenticate( user.uniqueid, user.password )
      flash[:notice] = @user.notice if @user.notice
      session[:user] = User.find( @user.id )
      session[:current_term] = Term.find_current
      
      if ( redirect && session[:post_login].nil? )
        redirect_to :controller => 'home' 
      else 
        redirect_to_url session[:post_login] if redirect
      end
      return true
    rescue SecurityError => doh
      if redirect
        @login_error = doh.message
        @user.password = '' 
        render :action => 'index' 
      end
      return false
    end
  end
  
  def rss_authorize(realm='Courseware RSS Authentication', errormessage='You must log in to view this page.') 
    # if they are already in an HTTP session (using browser based reader)
    unless session[:user].nil?
      @user = User.find(session[:user].id)
      return @user
    end
    
    username, passwd = get_auth_data 
    passwd = '' if passwd.nil?
    
    # check if authorized 
    # try to get user 
    user = User.new()
    user.uniqueid = username
    user.password = passwd 
    
    session[:post_login] = nil
    if authenticate( user, false )
      return @user         
    else  
      # the user does not exist or the password was wrong 
      @response.headers["Status"] = "Unauthorized" 
      @response.headers["WWW-Authenticate"] = "Basic realm=\"#{realm}\"" 
      render_text(errormessage, 401)     
      nil  
    end 
  end 

  def get_auth_data 
    user, pass = '', '' 
    
    @@auth_locations.each do |key|
      if request.env.has_key?(key)
        authdata = @request.env[key].to_s.split
        if authdata and authdata[0] == 'Basic' 
          user, pass = Base64.decode64(authdata[1]).split(':')[0..1] 
          logger.info("#{user},#{pass}")
          return user, pass
        end
      end
    end
    
    return user, pass
  end
  
  def count_todays_turnins( assignment, user, max = 3 )
    now = Time.now
    begin_time = Time.local( now.year, now.mon, now.day, 0, 0, 0 )
    end_time = begin_time + 60*60*24 # plus a day
    @today_count = UserTurnin.count( :conditions => [ "assignment_id = ? and user_id = ? and finalized = ? and updated_at >= ? and updated_at < ?", assignment.id, user.id, true, begin_time, end_time ] )
    @remaining_count = max - @today_count 
    @remaining_count = 0 if @remaining_count < 0
  end

  private :get_auth_data

end

class TrueClass
  def yes_no
    "Yes"
  end
end
class FalseClass
  def yes_no
    "No"
  end
end