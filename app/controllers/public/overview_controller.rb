require 'FreshItems'

class Public::OverviewController < ApplicationController
  before_filter :set_tab
  before_filter :load_user_if_logged_in
  
  def index
    return unless load_course( params[:course] )
    return unless course_is_public( @course )

    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @feed_id = @course.feed.id
    @pages, @feed_items = @course.feed.load_items(nil, 25, @page)
    
    set_title
  end
  
  def set_tab
     @show_course_tabs = true
     @tab = "course_overview"
   end

   def set_title
     @title = "#{@course.title} (Course Overview - Public Access)"
     @breadcrumb = Breadcrumb.for_course(@course)
     @breadcrumb.public_access = true
   end
   
   private :set_tab, :set_title

end
