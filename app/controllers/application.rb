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
    return true
  end

end