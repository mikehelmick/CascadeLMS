require 'FreshItems'

class Public::OverviewController < ApplicationController

  layout 'public'

  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless course_is_public( @course )
    
    @recent_activity = FreshItems.fresh( @course, @app['recent_items'].to_i, false )
    
    set_title
  end
  
  def set_tab
     @show_course_tabs = true
     @tab = "course_overview"
   end

   def set_title
     @title = "#{@course.title} (Course Overview - Public Access)"
   end
   
   private :set_tab, :set_title

end
