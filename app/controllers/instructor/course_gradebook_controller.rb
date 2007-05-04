class Instructor::CourseGradebookController < Instructor::InstructorBase
  
  layout 'noright'
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    process_grades( @course )
  end
  
  def settings
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    
    create_gradebook
    @gradebook = @course.gradebook
  end
  
  def save_settings
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    return unless course_open( @course, :action => 'index' )
    
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
    return unless course_open( @course, :action => 'index' )
    
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
    return unless course_open( @course, :action => 'index' )
    
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
    return unless course_open( @course, :action => 'index' )
    
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
    return unless course_open( @course, :action => 'index' )
    
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
    return unless course_open( @course, :action => 'index' )
    
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
  
  def set_weights
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    return unless course_open( @course, :action => 'index' )
    return unless course_weights_grades( @course )
    
    # get categories - and weights
    @weights = GradeWeight.reconcile( @course )
    
    @matrix = Array.new
    @weights.each { |w| @matrix[w.id] = w.percentage }    
  end
  
  def save_weights
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
    return unless course_open( @course, :action => 'index' )
    return unless course_weights_grades( @course )
    
    # get categories - and weights
    @weights = GradeWeight.reconcile( @course )
    
    ## update
    total = 0
    @weights.each do |w|
      w.percentage = sprintf("%.2f", params["weight_#{w.id}"] ).to_f
      total = total + w.percentage
    end
    
    if sprintf("%.2f",total).eql?("100.00")
      GradeWeight.transaction do 
        @weights.each { |w| w.save }
      end
      flash[:notice] = 'Grade category weights have been updated.'
      redirect_to :action => 'index'
    else 
      flash[:badnotice] = "Total is '#{total}'.  The total for all categories must add up to exactly 100.00."
      @matrix = Array.new
      @weights.each { |w| @matrix[w.id] = w.percentage }
      render :action => :set_weights
    end  
  end
  
  def export
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )    
  end
  
  def export_csv
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_gradebook' )
   
    process_grades( @course )
   
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'inline; filename=gradebook.csv'
    
    render :layout => false
  end
  
## private  
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
    @title = "Course GradeBook"
  end
  
  def item_in_course( course, item )
    unless course.id == item.course_id
      flash[:notice] = "You have requested an invalid Grade Book item."
      redirect_to :controller => '/instructor/course_gradebook', :course => course
      return false
    end
    return true
  end
  
  def create_gradebook
    unless @course.gradebook
      @course.gradebook = Gradebook.new 
      @course.gradebook.save
    end
  end
  
  def course_weights_grades( course )
    unless course.gradebook.weight_grades
      flash[:notice] = "This course does not have grade weighting enabled."
      redirect_to :controller => '/instructor/course_gradebook', :course => course
      return false
    end
    return true
  end
  
  def process_grades( course )
    # get the grade items and students
    @grade_items = course.grade_items
    @students = course.students
    @total_points = 0
    
    create_gradebook
    
    if @course.gradebook.weight_grades
      weights = GradeWeight.reconcile( course )
      @weight_map = Hash.new
      weights.each do |x| 
        @weight_map[x.grade_category_id] = x.percentage 
      end
      
      @cat_max_points = Hash.new
      @grade_items.each do |gi|
        if @cat_max_points[gi.grade_category_id].nil?
          @cat_max_points[gi.grade_category_id] = gi.points
        else
          @cat_max_points[gi.grade_category_id] += gi.points
        end
      end
    end
    
    if @students.size > 0
      @student_totals = Hash.new
      @student_cat_total = Hash.new
      @student_weighted = Hash.new
      @students.each do |s| 
        @student_totals[s.id] = 0
        @student_cat_total[s.id] = Hash.new
        @student_weighted[s.id] = 0
      end
      @category_total_points = Hash.new
      @grade_items.each { |gi| @category_total_points[gi.id] = 0 }
      # initialize grade matrix - one hash for each student
      @grade_matrix = Hash.new
      @students.each { |s| @grade_matrix[s.id] = Hash.new }
      # hash for average
      @averages = Hash.new
      ## hash for average w/o empty and w/o zero
      @average_no_blank = Hash.new
      @average_no_zero  = Hash.new
    
      ## OK - now we can do the calculations
      @grade_items.each do |gi|
        @averages[gi.id] = 0
        @average_no_blank[gi.id] = 0
        
        @total_points += gi.points
        
        gi.grade_entries.each do |ge|
          # verify the student exists
          unless @grade_matrix[ge.user_id].nil?
            @grade_matrix[ge.user_id][gi.id] = ge.points
            @averages[gi.id] += ge.points
            @student_totals[ge.user_id] += ge.points
            
            if @student_cat_total[ge.user_id][gi.grade_category_id].nil?
              @student_cat_total[ge.user_id][gi.grade_category_id] = ge.points
            else
              @student_cat_total[ge.user_id][gi.grade_category_id] += ge.points
            end
  
          end
        end
        
        ## need to calculate the empties
        @students.each do |student|
          if @grade_matrix[student.id][gi.id].nil? || @grade_matrix[student.id][gi.id] == 0
            @average_no_blank[gi.id] = @average_no_blank[gi.id] + 1
          end
        end
        
      end
    
      @categories = Array.new
      course.gradebook.grade_weights.each do |gw|
        if gw.percentage > 0
          @categories << gw
        end
      end
      
      # acutually weight the grades
      if course.gradebook.weight_grades
        @students.each do |student|
          #puts "#{student.inspect}"
          #puts "#{@student_cat_total[student.id].inspect}"
          
          weights.each do |weight|
            #puts "----------------"
            #puts "  gcid=#{weights.grade_category_id}"
            #puts "  tpts=#{cat_max_points[weights.grade_category_id]}"
            
            new_weight = @student_cat_total[student.id][weight.grade_category_id] rescue new_weight = 0
            #puts "  studentTotal=#{new_weight}"
            new_weight = new_weight / @cat_max_points[weight.grade_category_id] rescue new_weight = 0
            new_weight = new_weight * (@weight_map[weight.grade_category_id]/ 100.0)
            @student_weighted[student.id] += new_weight*100 ## sprintf("%.2f",new_weight*100).to_f
            
          end
          
          #puts "#{@student_weighted[student.id]}"
        end
      end
      
    end
  end
  
  private :set_tab, :item_in_course, :create_gradebook, :course_weights_grades, :process_grades
  
end
