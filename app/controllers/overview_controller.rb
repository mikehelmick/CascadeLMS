require 'FreshItems'

class OverviewController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @recent_activity = FreshItems.fresh( @course, @app['recent_items'].to_i )
    
    set_title
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_overview"
    @title = "Course Overview"
  end
  
  def set_title
    @title = "#{@course.title} (Course Overview)"
  end
  
end
