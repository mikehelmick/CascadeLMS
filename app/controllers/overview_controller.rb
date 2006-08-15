class OverviewController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    ## THIS FUNCTIONALITY SHOULD BE REFACTORED INTO THE RSS controller
    
    # show the last 30 items (whatever they may be)
    @blog_entries = Post.find(:all, :conditions => ["course_id=? and published=?",@course.id,true], :order => "created_at DESC", :limit => @app['recent_items'].to_i  )
    @documents = Document.find(:all, :conditions => ["course_id=?",@course.id], :order => "created_at DESC", :limit => @app['recent_items'].to_i  )
    time = Time.new
    @assignments = Assignment.find(:all, :conditions => ["course_id=? and open_date<=? and close_date>=?",@course.id,time,time], :order => "open_date DESC", :limit => @app['recent_items'].to_i  )
    @comments = Comment.find(:all, :conditions => ["course_id=?",@course.id], :order => "created_at DESC", :limit => @app['recent_items'].to_i  )
    
    @recent_activity = Array.new
    @blog_entries.each { |x| @recent_activity << x }
    @documents.each { |x| @recent_activity << x }
    @assignments.each { |x| @recent_activity << x }
    @comments.each { |x| @recent_activity << x }
    
    # sort
    @recent_activity.sort! do |a,b|
      if a.class.to_s.eql?("Assignment") && b.class.to_s.eql?("Assignment")
        a.open_date <=> b.open_date
      elsif a.class.to_s.eql?("Assignment")
        a.open_date <=> b.created_at
      elsif b.class.to_s.eql?("Assignment")
        a.created_at <=> b.open_date
      else
        a.created_at <=> b.created_at
      end
    end
    @recent_activity.reverse!
    
    
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
