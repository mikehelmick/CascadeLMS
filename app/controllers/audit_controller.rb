class AuditController < ApplicationController
  before_filter :ensure_logged_in, :ensure_program_auditor, :set_audit_term
  before_filter :set_tab, :except => [ :change_term ]

  verify :method => :post, :only => [ :toggle_opt_in ],
         :redirect_to => { :action => :index }

  # Lists all available 
  def index
    @programs = @user.programs_under_audit()
  end

  def program
    return unless load_program(params[:id])
    return unless allowed_to_audit_program(@program, @user)
    load_terms     

    @courses = @program.courses_in_term(@audit_term)
    
    @title = "Auditing for '#{@program.title}'"
  end

  def change_term
    return unless load_program(params[:id])
    return unless allowed_to_audit_program(@program, @user)

    @term = Term.find(params[:term])
    session[:audit_term] = @term
    @audit_term = @term

    @courses = @program.courses_in_term(@audit_term)

    render( :layout => false, :partial => 'courses' )
  end

  def course_outcomes
    return unless load_program(params[:id])
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course(params[:course])
    return unless course_in_program?( @course, @program )

    @numbers = load_outcome_numbers( @course )
    @title = "Course outcomes (#{@course.title}), Program outcomes (#{@program.title})"

    respond_to do |format|
        format.html { render :layout => 'noright' }
        format.csv  { 
          response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
          response.headers['Content-Disposition'] = "attachment; filename=#{@course.title}_course_outcomes_report.csv"
          render :layout => 'noright' 
        }
    end
  end

  def surveys
    return unless load_program(params[:id])
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course(params[:course])
    return unless course_in_program?( @course, @program )
    @title = "Entry/Exit surveys for #{@course.title}, program: #{@program.title}"

    load_surveys( @course.id )  
  end
  
  def compare_surveys
    return unless load_program(params[:id])
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course(params[:course])
    return unless course_in_program?( @course, @program )

    @title = "Entry/Exit survey comparison for #{@course.title}, program: #{@program.title}"

    error_url = url_for(:action => 'surveys', :id => @program, :course => @course)
    entry_exit_survey_compare(error_url)    
  end

  def rubric_report
    return unless load_program( params[:id] )
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    
    @title = "Rubric report for #{@course.title}, program: #{@program.title}"

    RubricLevel.for_course( @course )
     
    build_course_rubrics_report()
    
    respond_to do |format|
        format.html { render :layout => 'noright' }
        format.csv  { 
          response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
          response.headers['Content-Disposition'] = "attachment; filename=#{@course.short_description}_course_outcomes_rubrics_report.csv"
          render :layout => 'noright' 
        }
    end
  end

  def assignments
    return unless load_program( params[:id] )
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    
    @title = "Assignments for #{@course.title}, program: #{@program.title}"

    @assignments = @course.assignments
    # Filter out quizzes and surveys
    @assignments = @assignments.delete_if do |a|
      if a.quiz.nil?
        false
      else
        true
      end
    end
    
    load_audit_students()
  end

  def toggle_opt_in
    return unless load_program( params[:id] )
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    
    course_user = CoursesUser.find(:first, :conditions => ["user_id = ? and course_id = ? and course_student = ?", params[:user].to_i, @course.id, true])
    
    course_user.audit_opt_in = !course_user.audit_opt_in
    
    if course_user.save
      render(:layout => false, :partial => 'student', :locals => {:user => course_user, :course => @course, :program => @program, :error => nil})
    else 
      render(:layout => false, :partial => 'student', :locals => {:user => course_user, :course => @course, :program => @program, :error => "Error saving changes."})
    end
  end

  def turnins
    return unless load_program( params[:id] )
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    return unless load_assignment(params[:assignment])
    return unless assignment_in_course(@assignment, @course)
    
    @title = "Student work for '#{@assignment.title}', course '#{@course.title}', program: #{@program.title}"

    build_opt_in_hash()

    # Load the last turnin for student that have are opt in
    @userTurnins = Hash.new
    allTurnins = UserTurnin.find(:all, :conditions => ["assignment_id=?", @assignment.id], :order => "user_id asc, position desc")
    allTurnins.each do |ut|
      unless @optInIds[ut.user_id].nil?
        if @userTurnins[ut.user_id].nil?
          @userTurnins[ut.user_id] = ut
        end
      end
    end

    # Load the rubric entries (assigned per user)
    @rubricAssignment = Hash.new
    @userRubrics = Hash.new
    allRubricEntries = RubricEntry.find(:all, :conditions => ["assignment_id = ?", @assignment.id])
    allRubricEntries.each do |re|
      unless @optInIds[re.user_id].nil?
        @userRubrics[re.user_id] = Hash.new if @userRubrics[re.user_id].nil?
        @userRubrics[re.user_id][re.rubric_id] = re
      end
      
      if @rubricAssignment[re.rubric_id].nil?
       @rubricAssignment[re.rubric_id] = Hash.new
       @rubricAssignment[re.rubric_id][5] = 0
       @rubricAssignment[re.rubric_id][4] = 0
       @rubricAssignment[re.rubric_id][3] = 0
       @rubricAssignment[re.rubric_id][2] = 0
       @rubricAssignment[re.rubric_id][1] = 0
      end
      @rubricAssignment[re.rubric_id][4] += 1 if re.above_credit
      @rubricAssignment[re.rubric_id][3] += 1 if re.full_credit
      @rubricAssignment[re.rubric_id][2] += 1 if re.partial_credit
      @rubricAssignment[re.rubric_id][1] += 1 if re.no_credit
      @rubricAssignment[re.rubric_id][5] += 1 if re.above_credit || re.full_credit || re.partial_credit || re.no_credit
    end

    # outcome numbers needed to display rubrics
    @numbers = load_outcome_numbers(@course) if @assignment.rubrics.size > 0 
  end

  def journals
    return unless load_program( params[:id] )
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    return unless load_assignment(params[:assignment])
    return unless assignment_in_course(@assignment, @course)
    
    # make sure the student exists
    cuser = CoursesUser.find(:first, :conditions => ["course_id = ? and user_id = ?", @course.id, params[:student]])
    @student = nil
    if cuser.nil? || !cuser.user.student_in_course?( @course.id ) || !cuser.audit_opt_in
      @student = nil
    else
      @student = cuser.user
      @journals = Journal.find(:all, :conditions => ["assignment_id = ? and user_id = ?", @assignment.id, @student.id], :order => "start_time asc")
    end
    
    render(:layout => false)
  end

  def download_all
    return unless load_program( params[:id] )
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    return unless load_assignment(params[:assignment])
    return unless assignment_in_course(@assignment, @course)

    build_opt_in_hash()
    
    if @optInIds.size == 0
      flash[:badnotice] = "No students are opted in, no files to download."
      redirect_to :action => 'turnins', :id => @program, :course => @course, :assignment => @assignment
      return
    end

    ## create temp file for the archive
    tf = TempFiles.new
    tf.filename = "#{@app['temp_dir']}/#{@user.uniqueid}_assignment_#{@assignment.id}_all_files.zip"
    tf.save_until = Time.now + 60*24*24
    tf.save

    ## copy each of the latest turnins to a central point
    temp_dir = "#{@app['temp_dir']}/"
    file_tmp_dir = "#{Time.now.to_i}_#{@user.uniqueid}_assignment_#{@assignment.id}"
    
    FileUtils.mkdir_p( "#{temp_dir}#{file_tmp_dir}" )
    
    if @assignment.team_project
      teams = @course.project_teams
      # copy turnins for each team
      teams.each do |t|
        all_opt_in = true
        t.team_members.each do |tm|
          all_opt_in = all_opt_in && !@optInIds[tm.user.id].nil?
        end
        
        if all_opt_in
          uts = UserTurnin.find(:first, :conditions => ["project_team_id=? and assignment_id=?", t.id, @assignment.id ], :order => "created_at desc" )
          FileUtils.mkdir_p( "#{temp_dir}#{file_tmp_dir}/#{t.team_id}" )
          unless uts.nil?
            dir = uts.get_team_dir("#{@app['external_dir']}", t )
            command = "cd #{dir}; cp -R * #{temp_dir}#{file_tmp_dir}/#{t.team_id}"
            result = `#{command} 2>&1`
          end
        end
      end
    
    else
      students = @course.students
      # copy turnins
      students.each do |s|
        unless @optInIds[s.id].nil?
          uts = UserTurnin.find(:first, :conditions => ["user_id=? and assignment_id=?", s.id, @assignment.id ], :order => "created_at desc" )
          FileUtils.mkdir_p( "#{temp_dir}#{file_tmp_dir}/#{s.uniqueid}" )
          unless uts.nil?
            dir = uts.get_dir("#{@app['external_dir']}")
            command = "cd #{dir}; cp -R * #{temp_dir}#{file_tmp_dir}/#{s.uniqueid}"
            result = `#{command} 2>&1`
          end
        end
      end
    end
    
    #directory = @turnin.get_dir( @app['external_dir'] )
    #last_part = directory[directory.rindex('/')+1...directory.size]
    #first_part = directory[0...directory.rindex('/')]
    
    tar_cmd = "cd #{temp_dir}#{file_tmp_dir}; zip -q -r #{tf.filename} *"
    puts "#{tar_cmd}"
    result = `#{tar_cmd} 2>&1`
  
    if result.size > 0 
      flash[:badnotice] = "There was an error creating the download file, please try again later."
      redirect_to :action => 'turnins', :id => @program, :course => @course, :assignment => @assignment
      return
    end
  
    begin  
      send_file tf.filename, :filename => "#{@user.uniqueid}_assignment_#{@assignment.id}_all_files.zip"
      rescue
        flash[:badnotice] = "There was an error creating the download file, please try again later."
        redirect_to :action => 'turnins', :id => @program, :course => @course, :assignment => @assignment
    end
    
    # cleanup 
    #result = `cd #{temp_dir}; rm -r #{file_tmp_dir}`
  end

  # For downloading an assignment description file
  def download
    return unless load_program( params[:id] )
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    return unless load_assignment(params[:assignment])
    return unless assignment_in_course(@assignment, @course)

    @document = AssignmentDocument.find(params[:document]) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
    
    if @document.keep_hidden
      flash[:badnotice] = 'The requested document cannot be downloaded at this time.'
      redirect_to :action => 'view', :id => @assignment, :course => @course
      return
    end   
       
    begin  
      send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'inline'  
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your instructor of the problem and mention 'assignment document id #{@document.id}'."
      redirect_to :action => 'view', :id => @assignment, :course => @course
    end
  end

  def view_file
    return unless load_program( params[:id] )
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    return unless load_assignment(params[:assignment])
    return unless assignment_in_course(@assignment, @course)
    # In case the file needs to be resolved through a team directory
    return unless load_team( @course, @assignment, @user )

    cuser = CoursesUser.find(:first, :conditions => ["course_id = ? and user_id = ?", @course.id, params[:student]])
    if cuser.nil? || !cuser.user.student_in_course?( @course.id ) || !cuser.audit_opt_in
      flash[:badnotice] = "Invalid file requested"
      return redirect_to :action => 'turnins', :id => @program, :course => @course, :assignment => @assignment
    end
    
    @utf = UserTurninFile.find(params[:tif])
    if (@utf.user_turnin.assignment_id != @assignment.id)
      flash[:badnotice] = "Invalid file requested #{@utf.user_turnin.assignment_id} - #{@assignment.id}"
      return redirect_to :action => 'turnins', :id => @program, :course => @course, :assignment => @assignment
    end
    @turnin = @utf.user_turnin

    @directories = Hash.new
    @turnin.user_turnin_files.each do |utf|
      @directories[utf.id] = utf if utf.directory_entry?
    end

    directory = @turnin.get_dir( @app['external_dir'] )
  	directory = @turnin.get_team_dir( @app['external_dir'], @team ) unless @team.nil?
  	@lines = FileManager.format_file( @app['enscript_command'], "#{directory}#{@utf.full_filename( @directories )}", @utf.extension )
  	@comment_hash = @utf.file_comments_hash
  	@style_hash = @utf.file_style_hash

  	render :layout => false
  end

  def download_file
    return unless load_program( params[:id] )
    return unless allowed_to_audit_program(@program, @user)
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    return unless load_assignment(params[:assignment])
    return unless assignment_in_course(@assignment, @course)

    cuser = CoursesUser.find(:first, :conditions => ["course_id = ? and user_id = ?", @course.id, params[:student]])
    if cuser.nil? || !cuser.user.student_in_course?( @course.id ) || !cuser.audit_opt_in
      flash[:badnotice] = "Invalid file requested"
      return redirect_to :action => 'turnins', :id => @program, :course => @course, :assignment => @assignment
    end
    
    @utf = UserTurninFile.find(params[:tif])
    if (@utf.user_turnin.assignment_id != @assignment.id)
      flash[:badnotice] = "Invalid file requested #{@utf.user_turnin.assignment_id} - #{@assignment.id}"
      return redirect_to :action => 'turnins', :id => @program, :course => @course, :assignment => @assignment
    end
    @turnin = @utf.user_turnin

    # get the file and download it :)
    if @assignment.team_project
      team = @turnin.project_team
      directory = @turnin.get_team_dir( @app['external_dir'], team )
    else
      directory = @turnin.get_dir( @app['external_dir'] )
    end

    relative_name = @utf.filename
    walker = @utf
    while walker.directory_parent > 0 
      walker = UserTurninFile.find(walker.directory_parent)
      relative_name = "#{walker.filename}/#{relative_name}"
    end
    filename = "#{directory}#{relative_name}"

    begin  
      send_file filename, :filename => @utf.filename
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your system administrator if this problem continues."
      redirect_to :action => 'turnins', :id => @program, :course => @course, :assignment => @assignment
    end
  end

private
  def set_tab
    @tab = 'audit'
  end

  def build_opt_in_hash()
    # Build a hash of opt-in students
    @optInIds = Hash.new
    @course.students_courses_users.each do |cu|
      @optInIds[cu.user_id] = cu.user if cu.course_student && cu.audit_opt_in
    end
  end

  def document_in_assignment( document, assignment )
    unless document.assignment_id == assignment.id 
      flash[:badnotice] = "The requested document could not be found."
      redirect_to :action => 'turnins', :assignment => assignment, :course => @course, :id => @program
      return false
    end
    true
  end
  
  def load_team( course, assignment, user )
    @team = nil
    if assignment.team_project
      @team = course.team_for_user( user.id )
      unless @team.nil?
        return true
      end
      
      flash[:badnotice] = "This is a group project and requires assignment to a team in order to turn in files.  Please contact your instructor to be assigned to a team."
      redirect_to :action => 'assignments', :course => course.id, :id => @program, :assignment => assignment
      return false
    end
    return true #no team required
  end

  # @Override
  def assignment_in_course( assignment, course, redirect = true )
    unless assignment.course_id == course.id 
      flash[:badnotice] = "The requested assignment could not be found."
      redirect_to :action => 'assignments', :course => course if redirect
      return false
    end
    true
  end

  def load_audit_students
    @students = @course.students_courses_users
    
    size = @students.size / 2
    
    @column1 = Array.new
    0.upto(size) { |i| @column1 << @students[i] }
    @column2 = Array.new
    (size+1).upto(@students.size-1) { |i| @column2 << @students[i] }
  end

  def load_terms
    @terms = Term.find(:all)
  end

  def set_audit_term
    if session[:audit_term].nil?
      session[:audit_term] = Term.find_current
    end
    @audit_term = session[:audit_term]
  end

  def course_in_program?( course, program )
    if course.mapped_to_program?( program.id )
      return true
    end
    
    flash[:badnotice] = "Invalid course requested."
    redirect_to :controller => 'audit', :action => 'program', :id => program
    return false
  end
end
