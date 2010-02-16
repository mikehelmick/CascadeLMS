class GradesController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @grade_items = @course.sorted_grade_items
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
    
    # Weighting
    if !@course.gradebook.nil? && @course.gradebook.weight_grades
      weights = GradeWeight.reconcile( @course )
      @weight_map = Hash.new
      weights.each { |x| @weight_map[x.grade_category_id] = x.percentage }
      
      cat_max_points = Hash.new
      @grade_items.each do |gi|
        if cat_max_points[gi.grade_category_id].nil?
          cat_max_points[gi.grade_category_id] = gi.points if gi.visible
        else
          cat_max_points[gi.grade_category_id] += gi.points if gi.visible
        end
      end
      
      @student_cat_total = Hash.new
      grades.each do |x|
        if @student_cat_total[x.grade_item.grade_category_id].nil?
          @student_cat_total[x.grade_item.grade_category_id] = x.points
        else
          @student_cat_total[x.grade_item.grade_category_id] += x.points
        end
      end
    
      @weighted_average = 0
      # acutually weight the grades
      weights.each do |weights|
        begin
          @weighted_average = @weighted_average +
             @student_cat_total[weights.grade_category_id] / 
             cat_max_points[weights.grade_category_id] *
             @weight_map[weights.grade_category_id]
        rescue
          
        end
      end
      
    
    end
    
    set_title
    
    respond_to do |format|
      format.html
      format.xml { 
        render :layout => false 
      }
    end
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
