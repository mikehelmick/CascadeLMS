class Instructor::RubricsController< Instructor::InstructorBase
 
 before_filter :ensure_logged_in
 before_filter :set_tab

 def index
   return unless common_data_load( params ) 
   @title = "Rubrics for '#{@assignment.title}'"
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

       set_highlight = "rubric_#{@rubric.id}"
       flash[:notice] = 'New rubric has been saved.'
       redirect_to :action => 'index', :course => @course, :assignment => @assignment
     else
       @title = "New Rubric for '#{@assignment.title}'"
       render :action => 'new', :course => @course, :assignment => @assignment
     end
   end
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

end
