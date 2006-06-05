class Instructor::CourseAssignmentsController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
 
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
  
  end
  
  def new
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )

    @assignment = Assignment.new
    @journal_field = JournalField.new
    @categories = GradeCategory.for_course( @course )
  end
  
  def create
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    do_exit = false
    # create the assignment
    @assignment = Assignment.new( params[:assignment] )
    @assignment.course = @course
    @assignment.grade_category_id = params[:grade_category_id].to_i
    # see if we got a document
    if params[:file]
      if params[:file].nil? || params[:file].type.to_s.eql?('String')
        flash[:badnotice] = "You must upload an assignment file, or enter a description."
        do_exit = true;
      else
        @asgm_document = AssignmentDocument.new
        @asgm_document.set_file_props( params[:file] )
        @assignment.assignment_documents << @asgm_document
        @assignment.file_uploads = true
        @assignment.description = nil
      end
    end
    # see if we need to create a journal settings
    if @assignment.enable_journal
      @journal_field = JournalField.new( params[:journal_field] )
      @assignment.journal_field = @journal_field
    end
    
    # do the save
    if !do_exit && @assignment.save
       unless @asgm_document.nil?
         @asgm_document.create_file( params[:file], @app['external_dir'] )
       end
       
       flash[:notice] = 'Assignment was successfully created, you may now upload additional documents and specify auto-grading parameters.'
       redirect_to :action => 'index'
    else
       @journal_field = JournalField.new if @journal_field.nil?
       @categories = GradeCategory.for_course( @course )
      
       render :action => 'new'
    end
    # if @document.save
    #  @document.create_file( params[:file], @app['external_dir'] )
    
  end
  
  def move_up
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    @assignment = Assignment.find @params['id'] rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    (@course.assignments.to_a.find {|s| s.id == @assignment.id}).move_higher
    set_highlight "assignment_#{@assignment.id}"
  	redirect_to :action => 'index'
  end
  
  def move_down
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    @assignment = Assignment.find @params['id'] rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    (@course.assignments.to_a.find {|s| s.id == @assignment.id}).move_lower
    set_highlight "assignment_#{@assignment.id}"
  	redirect_to :action => 'index'
  end
  
  def destroy
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    @assignment = Assignment.find( @params['id'] )
    return unless assignment_in_course( @course, @assignment )
    
    @assignment.destroy
    flash[:notice] = 'Assignment Deleted'
    redirect_to :action => 'index'
  end
  
  def edit
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    @assignment = Assignment.find( @params['id'] )
    return unless assignment_in_course( @course, @assignment )   
    
    @journal_field = JournalField.new if @assignment.journal_field.nil?
    @categories = GradeCategory.for_course( @course ) 
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "Course Assignments - #{@course.title}"
  end
  
  def assignment_in_course( course, assignment )
    unless course.id == assignment.course.id
      redirect_to :controller => '/instructor/index', :course => course
      flash[:notice] = "Requested assignment could not be found."
      return false
    end
    true
  end
  
  private :set_tab, :set_title, :assignment_in_course
  
end
