# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  
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
 	
 	def ensure_logged_in
 	  if session[:user].nil?
 	    flash[:badnotice] = "You must log in before proceeding."
 	    redirect_to :controller => '/index'
 	    return false
    end
    # duplicate user - to keep session down
    @user = User.find(session[:user].id)
    return true
  end
  
  def allowed_to_see_course( course, user )
    user.courses_users.each do |cu|
      if cu.course_id == course.id
        if cu.course_student || cu.course_assistant || cu.course_instructor || cu.course_guest
          return true
        end
      end  
    end
    flash[:badnotice] = "You are not authorized to view the requested course."
    redirect_to :controller => '/home'
    return false
  end
  
  def load_course( course_id )
    begin
      @course = Course.find( course_id )
    rescue
      flash[:badnotice] = "Requrest course could not be found."
      redirect_to :controller => '/home'
      return
    end
  end

end