class Instructor::CourseGradebookController < Instructor::InstructorBase
  
  layout 'noright'
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    # get the grade items and students
    @grade_items = @course.grade_items
    @students = @course.students
    @total_points = 0
    
    if @students.size > 0
      @student_totals = Hash.new
      @students.each { |s| @student_totals[s.id] = 0 }
      # initialize grade matrix - one hash for each student
      @grade_matrix = Hash.new
      @students.each { |s| @grade_matrix[s.id] = Hash.new }
      # hash hor average
      @averages = Hash.new
    
      ## OK - now we can do the calculations
      @grade_items.each do |gi|
        @averages[gi.id] = 0
        @total_points += gi.points
        
        gi.grade_entries.each do |ge|
          # verify the student exists
          unless @grade_matrix[ge.user_id].nil?
            @grade_matrix[ge.user_id][gi.id] = ge.points
            @averages[gi.id] += ge.points
            @student_totals[ge.user_id] += ge.points
          end
        end
      end
      
    end
    
  end
  
  def settings
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    unless @course.gradebook
      @course.gradebook = Gradebook.new 
      @course.gradebook.save
    end
    @gradebook = @course.gradebook
  end
  
  def save_settings
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    @gradebook = @course.gradebook
    if @gradebook.update_attributes(params[:gradebook])
      flash[:notice] = 'Grade Book settings were successfully updated.'
      redirect_to :controller => '/instructor/course_gradebook', :course => @course
    else
      render :action => 'index'
    end
  end
  
  def item
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    # either the existing - or a new one
    @grade_item = GradeItem.find(params[:id]) rescue @grade_item = nil
    unless @grade_item.nil?
      return unless item_in_course( @course, @grade_item )
    end
    
    @grade_item = GradeItem.new if @grade_item.nil? # for some reason above isn't working
    @categories = GradeCategory.for_course( @course )
  end
  
  def delete_item
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    @grade_item = GradeItem.find(params[:id]) rescue @grade_item = nil
    return unless item_in_course( @course, @grade_item )
    
    if  @grade_item.destroy
      flash[:notice] = 'Item deleted.'
    else 
      flash[:badnotice] = 'There was an error deleting the selected item.'
    end
    redirect_to :controller => '/instructor/course_gradebook', :course => @course
  end
  
  def save_item
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    if ( params[:id] ) # existing
      @grade_item = GradeItem.find(params[:id]) rescue @grade_item = nil
      unless @grade_item
        return unless item_in_course( @course, @grade_item )
      end
      
      if @grade_item.update_attributes(params[:grade_item])
        flash[:notice] = "Grade item '#{@grade_item.name}' was successfully updated."
        redirect_to :controller => '/instructor/course_gradebook', :course => @course
      else
        @categories = GradeCategory.for_course( @course )
        render :action => 'item'
      end
      
    else # not-existing
      @grade_item = GradeItem.new(params[:grade_item])
      @grade_item.course = @course
      if @grade_item.save
        flash[:notice] = 'Grade item was successfully created.'
        redirect_to :controller => '/instructor/course_gradebook', :course => @course
      else
        @categories = GradeCategory.for_course( @course )
        render :action => 'item'
      end
    end
  end
  
  def enter
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    @grade_item = GradeItem.find(params[:id]) rescue @grade_item = nil
    return unless item_in_course( @course, @grade_item )
    
    @students = @course.students
    
    @grade_matrix = Hash.new
    ## OK - now we can do the calculations
    @grade_item.grade_entries.each do |ge|
      @grade_matrix[ge.user_id] = ge.points
    end
  end
  
  def save_grades
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    @grade_item = GradeItem.find(params[:id]) rescue @grade_item = nil
    return unless item_in_course( @course, @grade_item )
    
    @students = @course.students
    
    ## pull all the grades in
    student_grades = Hash.new
    @students.each do |s| 
      student_grades[s.id] = params["student_#{s.id}_item_#{@grade_item.id}"] 
    end
 
    GradeEntry.transaction do       
      ## read back existing grades and see if they should be updates
      @grade_item.grade_entries.each do |entry|
        if student_grades[entry.user.id].eql?("")
          entry.destroy
        else
          entry.points = student_grades[entry.user.id].to_f
          entry.save
        end
        student_grades.delete(entry.user.id)
      end
    
      # now create the news ones
      student_grades.each do |sid,grade|
        unless grade.eql?("")
          entry = GradeEntry.new
          entry.grade_item = @grade_item
          entry.user_id = sid
          entry.course = @course
          entry.points = grade.to_f
          entry.save
        end
      end
    end # end transaction
        
    redirect_to :controller => '/instructor/course_gradebook', :course => @course
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
    @title = "Course Settings"
  end
  
  def item_in_course( course, item )
    unless course.id == item.course_id
      flash[:notice] = "You have requested an invalid Grade Book item."
      redirect_to :controller => '/instructor/course_gradebook', :course => course
      return false
    end
    return true
  end
  
  private :set_tab, :item_in_course
  
end
