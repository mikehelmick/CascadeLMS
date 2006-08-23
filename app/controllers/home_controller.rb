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
    
    @other_courses = @user.courses
    @other_courses.sort! { |x,y| y.term.term <=> x.term.term }
    @other_courses.delete_if { |x| x.term.id == @term.id }
  end
  
  
  def set_tab
    @tab = 'home'
    @term = Term.find_current
  end
  
end
