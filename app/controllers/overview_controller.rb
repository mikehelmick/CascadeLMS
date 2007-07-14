require 'FreshItems'
require 'MyTime'

class OverviewController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @recent_activity = FreshItems.fresh( @course, @app['recent_items'].to_i )
    
    set_title
  end
  
  def calendar
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    now = Time.now
    @display_month = Time.mktime( now.year, now.month )
    unless params[:month].nil?
      if params[:month].length == 6
        begin
          valid_int = params[:month].to_i
          @display_month = Time.mktime( params[:month][0...4], params[:month][4..5] )
        rescue Exception => e          
        end
      end
    end
    
    item_list = FreshItems.month( @course, @display_month )
    
    @next_month = @display_month.nextMonth
    
    @items = Hash.new
    1.upto(31) { |i| @items[i] = Array.new }
    item_list.each do |a|
      if a.class.to_s.eql?("Assignment")
        if a.open_date >= @display_month && a.open_date <= @next_month
          @items[a.open_date.day] << a
        end
        if a.close_date >= @display_month && a.close_date <= @next_month
          @items[a.close_date.day] << a
        end
      else
        @items[a.created_at.day] << a
      end
    end
    
    puts item_list.inspect
    
  end
  
  private
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_overview"
    @title = "Course Overview"
  end
  
  def set_title
    @title = "#{@course.title} (Course Overview)"
  end
  
end
