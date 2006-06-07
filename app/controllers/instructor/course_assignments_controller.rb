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
    do_exit = process_file( params[:file] )
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
    
    @assignment.assignment_documents.each { |x| x.delete_file( @app['external_dir'] ) }
    
    @assignment.destroy
    flash[:notice] = 'Assignment Deleted'
    redirect_to :action => 'index'
  end
  
  def edit
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    @assignment = Assignment.find( @params['id'] )
    return unless assignment_in_course( @course, @assignment )   
    
    @journal_field = @assignment.journal_field
    @journal_field = JournalField.new if @assignment.journal_field.nil?
    @categories = GradeCategory.for_course( @course ) 
  end
  
  def update
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    @assignment = Assignment.find( @params['id'] )
    return unless assignment_in_course( @course, @assignment )
    
    begin
      raise 'Assignment update failed.' unless @assignment.update_attributes(params[:assignment]) 
      if @assignment.enable_journal
        if @assignment.journal_field.nil?
          @journal_field = JournalField.new( params[:journal_field] )
          @assignment.journal_field = @journal_field
          @assignment.save
        else
          @assignment.journal_field.update_attributes( params[:journal_field] )
        end
      else
        @assignment.journal_field.destroy unless @assignment.journal_field.nil?
      end
      
      ## see if there is a file to upload
      do_exit = process_file( params[:file], true )
      unless @asgm_document.nil?
         @asgm_document.create_file( params[:file], @app['external_dir'] )
         @assignment.file_uploads = true
         @assignment.save
      end
      
      flash[:notice] = 'Assignment has been updated.'
      redirect_to :action => 'edit', :course => @course, :id => @assignment
    rescue RuntimeError => re
      flash[:badnotice] = re.message
      redirect_to :action => 'edit', :course => @course, :id => @assignment
    end
        
  end
  
  
  def file_move_up
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    @assignment = Assignment.find @params[:id] rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    @document = AssignmentDocument.find( @params[:document] ) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    (@assignment.assignment_documents.to_a.find {|s| s.id == @document.id}).move_higher
    set_highlight "assignment_document_#{@document.id}"
  	redirect_to :action => 'edit', :course => @course, :id => @assignment
  end
  
  def file_move_down
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    @assignment = Assignment.find( @params[:id] ) rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    @document = AssignmentDocument.find( @params[:document] ) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    (@assignment.assignment_documents.to_a.find {|s| s.id == @document.id}).move_lower
    set_highlight "assignment_document_#{@document.id}"
  	redirect_to :action => 'edit', :course => @course, :id => @assignment
  end
  
  def file_delete
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    @assignment = Assignment.find( @params[:id] ) rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    @document = AssignmentDocument.find( @params[:document] ) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    if @assignment.assignment_documents.size == 1 && (@assignment.description.nil? || @assignment.description.size == 0)
      flash[:badnotice] = "You can not remove the last file from this assignment unless a textual description is entered first."
    else
      @document.destroy
    end
    redirect_to :action => 'edit', :course => @course, :id => @assignment    
  end
  
  def download
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    
    @assignment = Assignment.find( @params[:id] ) rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    @document = AssignmentDocument.find( @params[:document] ) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    begin  
      send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'download'  
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your administrator of the problem and mention 'document id #{@document.id}'."
      redirect_to :action => 'index'
    end
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
  
  def document_in_assignment( document, assignment )
    unless document.assignment.id == assignment.id
      redirect_to :controller => '/instructor/course_assignments', :action => 'edit', :id => assignment.id, :course => @course
      flash[:notice] = "Requested document could not be found."
      return false
    end
    true   
  end
  
  def process_file( file_param, supress_error = false )
    # see if we got a document
    if file_param
      if file_param.nil? || file_param.class.to_s.eql?('String')
        flash[:badnotice] = "You must upload an assignment file, or enter a description." unless supress_error
        return true
      else
        @asgm_document = AssignmentDocument.new
        @asgm_document.set_file_props( file_param )
        @assignment.assignment_documents << @asgm_document
        @assignment.file_uploads = true
        @assignment.description = nil
        return false
      end
    end
  end 
  
  private :set_tab, :set_title, :assignment_in_course
  
end
