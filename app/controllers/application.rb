require 'BasicAuthentication'
require 'LdapAuthentication'

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  
  layout 'application'
  
  before_filter :app_config
  after_filter :pull_msg
  
  def pull_msg
    if session[:user] && session[:user].notice
      flash[:notice] = "#{flash[:notice]} #{session[:user].notice}"
      session[:user].notice = nil
    end
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
    unless session[:user].admin?
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
 	
 	def ensure_logged_in
 	  if session[:user].nil?
 	    flash[:notice] = "Please log in."
 	    redirect_to :controller => '/index'
 	    return false
    end
    # duplicate user - to keep session down
    @user = User.find(session[:user].id)
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
      session[:user] = User.find( @user.id )
      redirect_to :controller => 'home' if redirect 
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
  
  def rss_authorize(realm='RSS Authentication', errormessage="You must log in to view this page.") 
    ## if they are already in an HTTP session (using browser based reader)
    #unless session[:user].nil?
    #  return User.find(session[:user].id)
    #end
    
    username, passwd = get_auth_data 
    passwd = '' if passwd.nil?
    
    # check if authorized 
    # try to get user 
    user = User.new()
    user.uniqueid = username
    user.password = passwd 
    
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
    # extract authorisation credentials 
    if request.env.has_key? 'X-HTTP_AUTHORIZATION' 
      # try to get it where mod_rewrite might have put it 
      authdata = @request.env['X-HTTP_AUTHORIZATION'].to_s.split 
    elsif request.env.has_key? 'HTTP_AUTHORIZATION' 
      # this is the regular location 
      authdata = @request.env['HTTP_AUTHORIZATION'].to_s.split  
    end 
      # at the moment we only support basic authentication 
    if authdata and authdata[0] == 'Basic' 
      user, pass = Base64.decode64(authdata[1]).split(':')[0..1] 
    end 
    return [user, pass] 
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