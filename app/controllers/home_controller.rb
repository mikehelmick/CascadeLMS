class HomeController < ApplicationController
  
  before_filter :ensure_logged_in
  
  def initialize()
    @title = "CS Courseware Home"
  end
  
  def index
    set_tab
    
    @title = "Home for #{@user.display_name}"
    @announcements = Announcement.current_announcements
    @courses = @user.courses_in_term( @term )
  end
  
  
  def set_tab
    @tab = 'home'
    @term = Term.find_current
  end
  
end
