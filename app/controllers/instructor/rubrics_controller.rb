class Instructor::RubricsController< Instructor::InstructorBase
 
 before_filter :ensure_logged_in
 before_filter :set_tab

 layout 'noright'

 def index
   return unless common_data_load( params ) 
   @title = "Rubrics for '#{@assignment.title}'"
   @numbers = load_outcome_numbers( @course )
   
   @all_rubrics = @course.rubrics
   @all_rubrics.sort do |a,b|
     res = a.assignment.position <=> b.assignment.position
     res = a.position <=> b.position if res == 0
     res 
   end
 end
 
 def new
   return unless common_data_load( params )
   @rubric = Rubric.new
   @title = "New Rubric for '#{@assignment.title}'"
 end
 
 def create
   return unless common_data_load( params )
  
   @rubric = Rubric.new(params[:rubric])
   @rubric.assignment = @assignment
   @rubric.course = @course
  
   Rubric.transaction do 
     if @rubric.save
       @course.course_outcomes.each do |course_outcome|
          @rubric.course_outcomes << course_outcome unless params["course_outcome_#{course_outcome.id}"].nil? 
       end
       @rubric.save

       set_highlight( "rubric_#{@rubric.id}" )
       flash[:notice] = 'New rubric has been saved.'
       redirect_to :action => 'index', :course => @course, :assignment => @assignment
     else
       @title = "New Rubric for '#{@assignment.title}'"
       render :action => 'new', :course => @course, :assignment => @assignment
     end
   end
 end
 
 def edit
   return unless common_data_load( params )  
   return unless load_rubric( params[:id] )
 end
 
 def update
   return unless common_data_load( params )
   return unless load_rubric( params[:id] )
   
   Rubric.transaction do
     @rubric.update_attributes(params[:rubric])
     
     @rubric.course_outcomes.clear
     @course.course_outcomes.each do |course_outcome|
        unless params["course_outcome_#{course_outcome.id}"].nil? 
          @rubric.course_outcomes << course_outcome
          @rubric.save
        end
     end
     @rubric.save
     
     set_highlight( "rubric_#{@rubric.id}" )
     flash[:notice] = 'The rubric has been updated.'
     redirect_to :action => 'index', :course => @course, :assignment => @assignment
     return
   end
   
   flash[:badnotice] = "There was an error saving your changes."
   redirect_to :action => 'edit', :course => @course, :assignment => @assignment, :id => @rubric
 end
 
 def destroy
   return unless common_data_load( params )
   return unless load_rubric( params[:id] )
   
   @rubric.destroy
   flash[:notice] = "The selected rubric has been deleted."
   redirect_to :controller => '/instructor/rubrics', :course => @course, :assignment => @assignment 
 end
 
 def import_rubric
   return unless common_data_load( params )
   return unless load_rubric_validate_course( params[:id].to_i, @course )
  
   @new_rubric = @rubric.clone
   @new_rubric.assignment = @assignment
   @new_rubric.course = @course
   @new_rubric.primary_trait = @rubric.primary_trait
   @new_rubric.no_credit_criteria = @rubric.no_credit_criteria
   @new_rubric.no_credit_points = @rubric.no_credit_points
   @new_rubric.part_credit_criteria = @rubric.part_credit_criteria
   @new_rubric.part_credit_points = @rubric.part_credit_points
   @new_rubric.full_credit_criteria = @rubric.full_credit_criteria
   @new_rubric.full_credit_points = @rubric.full_credit_points
   @new_rubric.visible_before_grade_release = @rubric.visible_before_grade_release
   @new_rubric.visible_after_grade_release = @rubric.visible_after_grade_release
   
   Rubric.transaction do
     @new_rubric.save
     @rubric.course_outcomes.each do |course_outcome|
         @new_rubric.course_outcomes << course_outcome
     end
     @new_rubric.save
      
     set_highlight( "rubric_#{@rubric.id}" )
     flash[:notice] = 'The selected rubric has been imported into this assignment.'
     redirect_to :action => 'index', :course => @course, :assignment => @assignment
     return
   end
   
   flash[:badnotice] = "There was an error saving your changes."
   redirect_to :action => 'index', :course => @course, :assignment => @assignment
 end
  
 private
 
 def common_data_load( params )
   return false unless load_course( params[:course] )
   return false unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
   return false unless course_open( @course, {:controller => '/instructor/course_assignments', :action => 'index'} )
   
   @assignment = Assignment.find( params[:assignment] )
   return false unless assignment_in_course( @course, @assignment )
   return true
 end

 def load_rubric( id )
   @rubric = Rubric.find(id) rescue @rubric = nil
   if @rubric.nil? || @assignment.id != @rubric.assignment_id
     flash[:badnotice] = "The requested rubric could not be found."
     redirect_to :controller => '/instructor/rubrics', :course => @course, :assignment => @assignment 
     return false
   end
   return true
 end
 
 def load_rubric_validate_course( id, course )
   @rubric = Rubric.find(id) rescue @rubric = nil
   if @rubric.nil? || @course.id != @rubric.course_id
     flash[:badnotice] = "The requested rubric could not be found."
     redirect_to :controller => '/instructor/rubrics', :course => @course, :assignment => @assignment 
     return false
   end
   return true 
 end
 
end
