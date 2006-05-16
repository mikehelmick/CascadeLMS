# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  
  before_filter :app_config

  def app_config
 		@app ||= YAML.load( File.open("#{RAILS_ROOT}/config/defaults.yml") )
 	end
 	
 	def ensure_instructor
 	  return false unless session[:user].instructor?
 	  return true
  end
  
  def ensure_admin
    return false unless session[:user].admin?
    return true
  end
 	
 	def ensure_logged_in
 	  if session[:user].nil?
 	    redurect_to :controller => '/index'
 	    return false
    end
    return true
  end

end