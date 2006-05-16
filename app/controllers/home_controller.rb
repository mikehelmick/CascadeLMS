class HomeController < ApplicationController
  
  before_filter :ensure_logged_in
  
  def initialize()
    @title = "CS Courseware Home"
  end
  
  def index
    @title = "Home for #{session[:user].display_name}"
    
    
    set_tab
  end
  
  
  def set_tab
    @tab = 'home'
  end
  
end
