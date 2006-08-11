class GradesController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @grade_items = @course.grade_items
    grades = GradeEntry.find(:all, :conditions => ["user_id=? and course_id=?", @user.id, @course.id ] )
    @total_points = 0
    @total_points_possible = 0
    
    @grade_map = Hash.new
    grades.each do |x| 
      if x.grade_item.visible
        @grade_map[x.grade_item_id] = x.points 
        @total_points += x.points
      end
    end
    
    @grade_items.each {|x| @total_points_possible += x.points if x.visible }
    
    set_title
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_grades"
    @title = "Grades"
  end
  
  def set_title
    @title = "Your Grades for #{@course.title}, #{@course.term.term}"
  end
  
  private :set_tab, :set_title
  
end
