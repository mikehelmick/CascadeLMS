class Instructor::CourseAssignmentsController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }
 
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments', 'ta_grade_individual', 'ta_view_student_files' )
  
    # make sure rubrics are loaded
    RubricLevel.for_course( @course )
  
    set_title
    
    render :layout => 'noright'
  end
  
  def reorder
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments', 'ta_grade_individual', 'ta_view_student_files' )
  
    set_title
    
    render :layout => 'noright'
  end
  
  def sort
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments', 'ta_grade_individual', 'ta_view_student_files' )
    
    
    # get the outcomes at this level
    Assignment.transaction do
      @course.assignments.each do |assignment|
        assignment.position = params['assignment-order'].index( assignment.id.to_s ) + 1
        assignment.save
      end
    end
    
    render :nothing => true
  end
  
  def new
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )

    @assignment = Assignment.new
    @journal_field = JournalField.new
    @categories = GradeCategory.for_course( @course )
    
    if @course.course_setting.enable_prog_assignments
      @assignment.programming = true
      @assignment.use_subversion = @course.course_setting.enable_svn
      if @assignment.use_subversion
        @assignment.subversion_server = @course.course_setting.svn_server
      end
    else
      @assignment.programming = false
      @assignment.use_subversion = false
      @assignment.auto_grade = false
    end
    
    set_title
    @title = "New Assignment"
    @duplicate = false
  end
  
  def create
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @points = params[:point_value]
    
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
    
    ags = AutoGradeSetting.new
    @assignment.auto_grade_setting = ags
    if !@assignment.auto_grade
      # get rid of defaults
      @assignment.auto_grade_setting.disable!      
    end
    
    # do the save
    begin
      Assignment.transaction do
        if !do_exit && @assignment.save
           unless @asgm_document.nil?
             if ! @asgm_document.create_file( params[:file], @app['external_dir'] )
               flash[:badnotice] = "Filenames cannot contain more than one period ('.') character and must have an extension."
               raise "filename" 
             end
           end

           ## style defaults
           if @assignment.auto_grade
             Assignment.transaction do 
               @assignment.ensure_style_defaults 
             end
           end

           # create grade item
           if !@points.nil? && @points.to_i > 0
             gi = GradeItem.new
             gi.name = @assignment.title
             gi.date = @assignment.due_date.to_date
             gi.points = @points.to_f
             gi.display_type = "s"
             gi.visible = false
             gi.grade_category_id = @assignment.grade_category_id
             gi.assignment_id = @assignment.id
             gi.course_id = @course.id

             gi.save
           end

           flash[:notice] = 'Assignment was successfully created, you may now upload additional documents and specify auto-grading parameters.'

           if @assignment.auto_grade
             redirect_to :action => 'autograde', :id => @assignment
           else
             redirect_to :action => 'index'
           end
        else
           @journal_field = JournalField.new if @journal_field.nil?
           @categories = GradeCategory.for_course( @course )
           render :action => 'new'
        end
      end
    rescue Exception => e
      flash[:badnotice] = "Filenames cannot contain more than one period ('.') character and must have an extension." unless params[:file].nil?
      @journal_field = JournalField.new if @journal_field.nil?
      @categories = GradeCategory.for_course( @course )
      render :action => 'new'
    end
    # if @document.save
    #  @document.create_file( params[:file], @app['external_dir'] )
    
  end
    
  def destroy
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @assignment = Assignment.find( params['id'] )
    return unless assignment_in_course( @course, @assignment )
    
    @assignment.assignment_documents.each { |x| x.delete_file( @app['external_dir'] ) }
    
    @assignment.destroy
    flash[:notice] = 'Assignment Deleted'
    redirect_to :action => 'index'
  end
  
  def autograde
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    @assignment = Assignment.find( params['id'] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )  
    
    if @assignment.auto_grade_setting.nil?
      @assignment.auto_grade_setting = AutoGradeSetting.new
      @assignment.save
    end
    
    @auto_grade_setting = @assignment.auto_grade_setting
  end
  
  def save_autograde
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    @assignment = Assignment.find( params['id'] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )  
    
    if @assignment.auto_grade_setting.update_attributes( params[:auto_grade_setting] ) 
      flash[:notice] = "AutoGrade settings changed."
    else
      flash[:badnotice] = "There was an error saving autograde settings."
    end
    
    redirect_to :action => 'autograde', :id => @assignment
  end
  
  def duplicate
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )

    
    @assignments = Array.new
    @course.assignments.each do |asgn|
      @assignments << asgn unless asgn.quiz
    end
    
    ## setup some basics 
    @assignment = Assignment.new
    @assignment.default_dates
    
    @duplicate = true
    
    @title = "Duplicate Assignment - #{@course.title}"    
  end
  
  def clone
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @copy_from = Assignment.find( params['copy_from_id'] )
    return unless assignment_in_course( @course, @copy_from )
    @assignmentDates = Assignment.new( params[:assignment] )    
    
    Assignment.transaction do 
      @assignment = @copy_from.clone_to_course( @course.id, @user.id, 0, @app['external_dir'] )

      @assignment.open_date  = @assignmentDates.open_date
      @assignment.due_date   = @assignmentDates.due_date
      @assignment.close_date = @assignmentDates.close_date
      @assignment.title = "copy: #{@assignment.title}"
      @assignment.save

      @assignment.auto_grade_setting = @copy_from.auto_grade_setting.clone rescue @assignment.auto_grade_setting = nil
      
      @copy_from.io_checks.each do |io|
        newIo = io.clone
        newIo.assignment_id = @assignment.id
        newIo.save
      end
      
      @assignment.save
      flash[:notice] = 'The selected assignment has been cloned to this one, you can continue to edit the details now.'

      @duplicate = false
      redirect_to :controller => '/instructor/course_assignments', :action => 'edit', :course => @course, :id => @assignment
    end
  end
    
  def edit
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @assignment = Assignment.find( params['id'] )
    return unless assignment_in_course( @course, @assignment )   
    
    @journal_field = @assignment.journal_field
    @journal_field = JournalField.new if @assignment.journal_field.nil?
    @categories = GradeCategory.for_course( @course ) 
    @title = "Edit #{@assignment.title} (#{@course.title})"
    @duplicate = false
  end
  
  def update
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @assignment = Assignment.find( params['id'] )
    return unless assignment_in_course( @course, @assignment )
    @points = params[:point_value]
    
    begin
      Assignment.transaction do
        @assignment.grade_category_id = params[:grade_category_id].to_i
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
        do_exit = process_file( params[:file], false )
        raise "All filenames must have an extension, but may only contain a single period ('.') character." if do_exit
        unless @asgm_document.nil?
          if ! @asgm_document.create_file( params[:file], @app['external_dir'] )
            flash[:badnotice] = "Filenames cannot contain more than one period ('.') character and must have an extension."
            raise "Filenames cannot contain more than one period ('.') character and must have an extension."
          end
          @assignment.file_uploads = true
          @assignment.save
        end
        
        if @assignment.grade_item
          if !@points.nil? && @points.to_i > 0
            @assignment.grade_item.points = @points.to_i
            @assignment.grade_item.save
          end
        end

        flash[:notice] = 'Assignment has been updated.'
        redirect_to :action => 'edit', :course => @course, :id => @assignment
      end
    rescue RuntimeError => re
      redirect_to :action => 'edit', :course => @course, :id => @assignment
    end
        
  end
  
  def pmd_settings
      return unless load_course( params[:course] )
      return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
      return unless course_open( @course, :action => 'index' )
      @assignment = Assignment.find( params['id'] )
      return unless assignment_in_course( @course, @assignment )
      return unless assignment_uses_autograde( @course, @assignment )
      return unless assignment_uses_pmd( @course, @assignment )
      
      
      @assignments = Array.new
      # load other assignments in the course
      assignments = Assignment.find(:all, :conditions => ["course_id = ?", @course.id], :order => "open_date asc" )
      assignments.each do |asgn|
        if asgn.auto_grade && ! asgn.auto_grade_setting.nil? && (asgn.auto_grade_setting.student_style || asgn.auto_grade_setting.style)
          @assignments << asgn unless asgn.id == @assignment.id
        end
      end
      
      # this isn't fun - make sure that pmd setting are available
      if @assignment.assignment_pmd_settings.size == 0
        unless @assignment.ensure_style_defaults
          flash[:badnotice] = "There was an error initialize the default Java style checks, please try again later."
          redirect_to :action => 'index', :course => @course
        else 
          flash[:notice] = "Initialized PMD settings to default values."
        end
      end
  end
  
  def copy_pmd
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    @assignment = Assignment.find( params['id'] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )
    return unless assignment_uses_pmd( @course, @assignment )
    
    @copy_from = Assignment.find( params['copy_from_id'])   
    return unless assignment_in_course( @course, @copy_from )
    return unless assignment_uses_autograde( @course, @copy_from )
    return unless assignment_uses_pmd( @course, @copy_from )
    
    begin
      pmds = @assignment.pmd_hash
      
      master = @copy_from.pmd_hash
      master.each do |id,pmd|
        pmds[id].enabled = pmd.enabled
        raise "error saving" unless pmds[id].save
      end
      
      flash[:notice] = "PMD settings have been copied."
    rescue Exception => e
      flash[:badnotice] = "There was an error updating the PMD setting for this assignment."
    end
    
    redirect_to :action => 'pmd_settings', :course => @course, :id => @assignment
  end
  
  def save_pmd
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    @assignment = Assignment.find( params['id'] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )
    return unless assignment_uses_pmd( @course, @assignment )
    
    begin
      AssignmentPmdSetting.transaction do
        pmds = @assignment.pmd_hash
        pmds.each do |id,pmd|
          #puts "KEY=#{id}"
          #puts pmd.inspect 
          #puts params["apmd_#{id}"]
          
          if params["apmd_#{id}"].nil?
            if pmd.enabled == true
              pmd.enabled = false
              raise "error saving" unless pmd.save
            end
          else
            unless pmd.enabled.to_s.eql?( params["apmd_#{id}"].to_s )
              pmd.enabled = ! pmd.enabled
              raise "error saving" unless pmd.save
            end
          end
        end
      end
      
      flash[:notice] = "PMD settings have been saved."
    rescue
      flash[:badnotice] = "There was an error updating the PMD setting for this assignment."
    end
  
    redirect_to :action => 'pmd_settings', :course => @course, :id => @assignment
  end
  
  def toggle_hidden
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @assignment = Assignment.find params[:id] rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    @document = AssignmentDocument.find( params[:document] ) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    @document.keep_hidden = !@document.keep_hidden
    @document.save
    
    set_highlight "assignment_document_#{@document.id}"
  	redirect_to :action => 'edit', :course => @course, :id => @assignment    
  end
  
  def toggle_auto_add
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @assignment = Assignment.find params[:id] rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    @document = AssignmentDocument.find( params[:document] ) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    @document.add_to_all_turnins = !@document.add_to_all_turnins
    @document.save
    
    set_highlight "assignment_document_#{@document.id}"
  	redirect_to :action => 'edit', :course => @course, :id => @assignment
  end
  
  def file_move_up
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @assignment = Assignment.find params[:id] rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    @document = AssignmentDocument.find( params[:document] ) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    (@assignment.assignment_documents.to_a.find {|s| s.id == @document.id}).move_higher
    set_highlight "assignment_document_#{@document.id}"
  	redirect_to :action => 'edit', :course => @course, :id => @assignment
  end
  
  def file_move_down
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @assignment = Assignment.find( params[:id] ) rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    @document = AssignmentDocument.find( params[:document] ) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    (@assignment.assignment_documents.to_a.find {|s| s.id == @document.id}).move_lower
    set_highlight "assignment_document_#{@document.id}"
  	redirect_to :action => 'edit', :course => @course, :id => @assignment
  end
  
  def file_delete
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @assignment = Assignment.find( params[:id] ) rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    @document = AssignmentDocument.find( params[:document] ) rescue @document = AssignmentDocument.new
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
    
    @assignment = Assignment.find( params[:id] ) rescue @assignment = Assignment.new
    return unless assignment_in_course( @course, @assignment )
    
    @document = AssignmentDocument.find( params[:document] ) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    begin  
      send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'download'  
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your administrator of the problem and mention 'document id #{@document.id}'."
      redirect_to :action => 'index'
    end
  end
  
  
  def team_filter
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @assignment = Assignment.find( params['id'] )
    return unless assignment_in_course( @course, @assignment )  
    @title = "Team Filter - #{@assignment.title}"
  end
  
  def update_team_filter
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :action => 'index' )
    
    @assignment = Assignment.find( params['id'] )
    return unless assignment_in_course( @course, @assignment )
   
    #begin 
      Assignment.transaction do 
       @assignment.team_filters.each { |i| i.destroy }
       
       @course.project_teams.each do |team|
         if !params["project_team_#{team.id}"].nil? &&  params["project_team_#{team.id}"].to_i == team.id
           filter = TeamFilter.new
           filter.assignment = @assignment
           filter.project_team = team
           filter.save
         end
       end
       
     end
     
      flash[:notice] = "Team filter settings have been saved."
    #rescue
    #  flash[:badnotice] = "Team filter changes could not be saved."
    #end  
      
    redirect_to :action => 'team_filter', :id => @assignment
  end
  
  
  
private  
  #### PRIVATE METHODS BELOW
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "Course Assignments - #{@course.title}"
  end

  
end
