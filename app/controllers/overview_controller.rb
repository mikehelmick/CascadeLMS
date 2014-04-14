#            **** SOFTWARE LICENSE - New BSD License ****
# Copyright (c) 2006-2013, Mike Helmick - mike.helmick@gmail.com
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
#  - Redistributions of source code must retain the above copyright notice, 
#    this list of conditions and the following disclaimer.
#  - Redistributions in binary form must reproduce the above copyright notice, 
#    this list of conditions and the following disclaimer in the documentation 
#    and/or other materials provided with the distribution.
#  - Neither the name of the Mike Helmick, Miami University nor the names of its
#    contributors may be used to endorse or promote products derived from this 
#    software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.

require 'FreshItems'
require 'MyTime'

# Controller for the opening view of a course.
#
# Author: mike.helmick@gmail.com - Mike Helmick
class OverviewController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab

  #layout 'application_right'
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    set_title

    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @feed_id = @course.feed.id
    @pages, @feed_items = @course.feed.load_items(@user, 25, @page)
    
    respond_to do |format|
      format.html {
      }
      format.xml {
        render :layout => false
      }
    end
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
    
    
  end
  
  private
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_overview"
    @title = "Course Overview"
  end
  
  def set_title
    @title = "#{@course.title} (Course Overview)"
    @breadcrumb = Breadcrumb.new
    @breadcrumb.course = @course
  end
  
end
