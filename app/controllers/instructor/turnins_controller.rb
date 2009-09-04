require 'SimpleProgramRunner'
require 'FileManager'
require 'DiffCount'

class Instructor::TurninsController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  layout 'noright'
  
  
  verify :method => :post, :only => [ :save_all_grades ],
         :redirect_to => { :action => :index }
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual', 'ta_view_student_files', 'ta_grade_individual' )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    if @assignment.released
      return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_already_graded_assignments' )
    end
    
    # load the students
    @students = @course.students
    
    if @assignment.enable_journal
      # count journals
      @journal_count = Hash.new
      @students.each do |s|
        @journal_count[s.id] = Journal.count( :conditions => ["user_id=? and assignment_id=?", s.id, @assignment.id ] )
      end
    end
    
    @any_turnins = false
    if @assignment.use_subversion || @assignment.enable_upload
      # see if turnins
      @turnin_sets = Hash.new
      @students.each do |s|
        if @assignment.team_project
          team = @course.team_for_user( s.id )
          if team.nil?
            @turnin_sets[s.id] = nil
          else
            @turnin_sets[s.id] = UserTurnin.find(:first,  :conditions => ["project_team_id=? and assignment_id=?", team.id, @assignment.id ], :order => "id desc" ) 
          end
        else 
          @turnin_sets[s.id] = UserTurnin.find(:first,  :conditions => ["user_id=? and assignment_id=?", s.id, @assignment.id ], :order => "id desc" ) 
        end
        @any_turnins = @any_turnins || @turnin_sets[s.id]
      end
    end
    
    # load grades
    @grade_item = GradeItem.find(:first, :conditions => ["assignment_id = ?", @assignment.id] )
    if @grade_item
      @grades = Hash.new
      entries = GradeEntry.find(:all, :conditions => ["grade_item_id=?", @grade_item.id ] )
      entries.each do |e|
        @grades[e.user_id] = e.points
      end
    end
    
    # load teams
    if @assignment.team_project
      # load teams
      @teams = Hash.new
      teams = ProjectTeam.find(:all, :conditions => ["course_id = ?", @course.id] )
      teams.each { |t| @teams[t.id] = t }
      
      # load members
      @team_members = Hash.new
      members = TeamMember.find(:all, :conditions => ["course_id = ?", @course.id] )
      members.each { |tm| @team_members[tm.user_id] = @teams[tm.project_team_id] }
        
    end
    
    ## If programming
    if @assignment.programming
      ## load the text file types for diff
      @textfiles = FileManager.text_extension_map.sort
      @diffsize = diff_arr
      @count = 25
    end
    
    @title = "Turnins for #{@assignment.title}"
  end
  
  def rubrics
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual', 'ta_view_student_files', 'ta_grade_individual' )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    if @assignment.rubrics.size == 0 
      flash[:badnotice] = 'This assignment has no rubrics to report on.'
      return redirect_to :course => @course, :action => 'index', :id => nil
    end
    
    @total_sum = [0,0,0]
    @total_avg = [0,0,0]
    
    @rubrics_sum = Hash.new
    @rubrics_avg = Hash.new
    @assignment.rubrics.each do |rubric|
      @rubrics_sum[rubric.id] = [0,0,0]
      @rubrics_avg[rubric.id] = [0,0,0]
      thisArr = @rubrics_sum[rubric.id]
      
      entries = RubricEntry.find(:all, :conditions => ['rubric_id = ?', rubric.id])
      entries.each do |re|
        thisArr[0] = thisArr[0]+1 if re.above_credit || re.full_credit
        thisArr[1] = thisArr[1]+1 if re.partial_credit
        thisArr[2] = thisArr[2]+1 if re.no_credit
      end
      
      @rubrics_sum[rubric.id] = thisArr
      
      sum = thisArr[0] + thisArr[1] + thisArr[2]
      if sum > 0
        0.upto(2) { |i| @rubrics_avg[rubric.id][i] = thisArr[i]/sum.to_f*100 }
      end    
      
      0.upto(2) { |i| @total_sum[i] = @total_sum[i] + @rubrics_sum[rubric.id][i] }
    end
    
    sum = @total_sum[0]+@total_sum[1]+@total_sum[2]
    if sum > 0
      0.upto(2) { |i| @total_avg[i] = @total_sum[i] / sum.to_f*100 }
    end
    
  end
  
  ## From the index / turnins page, we allow forall grades to be changed at once
  def save_all_grades
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual', 'ta_view_student_files', 'ta_grade_individual' )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    # load the students
    @students = @course.students
    
    ### FOR EACH STUDENT - PROCESS THE GRADE COMING IN FROM THE FORM
    @grade_item = GradeItem.find(:first, :conditions => ["assignment_id = ?", @assignment.id] )
    if @grade_item
      ## Load the current grade entries for each student
      ## Map these to the student's user ID
      @grades = Hash.new
      entries = GradeEntry.find(:all, :conditions => ["grade_item_id=?", @grade_item.id ] )
      entries.each do |e|
        @grades[e.user_id] = e
      end
      
      Assignment.transaction do
        ## go through and update the grades
        @students.each do |student|
          new_grade = params["grade_#{student.id}"]

          if @grades[student.id].nil?
            # no current entry
            unless new_grade.nil?
              entry = GradeEntry.new
              entry.user = student
              entry.grade_item = @grade_item
              entry.course = @course
              entry.points = new_grade.to_f
              entry.save
            end
            
          else
            ## existing entry
            if new_grade.nil? || new_grade.to_f < 0
              @grades[student.id].destroy
            else
              @grades[student.id].points = new_grade.to_f 
              @grades[student.id].save
            end
          end

        end
      end
      
      
      flash[:notice] = "Grades have been updated for all students."
      if @assignment.quiz.nil?  
        redirect_to :action => 'index', :course => @course, :assignment => @assignment
      else
        redirect_to :controller => '/instructor/results', :action => 'quiz', :course => @course, :assignment => @assignment
      end
      
    else
      flash[:badnotice] = "There is no gradebook entry associated with this assignment."
      redirect_to :action => 'index'
    end
  end
  
  def agsummary
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual', 'ta_view_student_files', 'ta_grade_individual' )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    # get turn-in sets
    if @assignment.team_project
      @team = @course.team_for_user( @student.id )
      @turnins = UserTurnin.find(:all, :conditions => ["project_team_id=? and assignment_id=?", @team.id, @assignment.id ], :order => "position DESC" )
    else
      @turnins = UserTurnin.find(:all, :conditions => ["user_id=? and assignment_id=?", @student.id, @assignment.id ], :order => "position DESC" )
    end
    
    @current_turnin = @turnins[0] rescue @current_turnin = nil
    unless @current_turnin.nil?
      @display_turnin = @current_turnin
      return unless turnin_for_assignment( @current_turnin, @assignment )   

      # turnins
      @student_io_check = Hash.new
      @assignment.io_checks.each do |check|
         student_check = IoCheckResult.find(:first, :conditions => ["io_check_id = ? && user_turnin_id = ?", check.id, @current_turnin.id ] )
         unless student_check.nil?
           @student_io_check[check.id] = student_check
         end
      end
      
      @pmd_summary = Array.new
      @current_turnin.user_turnin_files.each do |tif|
        tif.file_styles.each do |fs|
          unless fs.suppressed
            @pmd_summary << "#{tif.filename}:#{fs.begin_line} - #{fs.style_check.name}: <i>#{fs.style_check.description}</i>"
          end
        end
      end
    
    end
    
    ### NEED TO FINISH THIS
    render :partial => 'agsummary', :layout => false
  end
  
  def toggle_released
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless course_open( @course, :action => 'index' )
    
    Assignment.transaction do
      @assignment.released = !@assignment.released
      unless @assignment.save
        flash[:badnotice] = "Error changing assignment comments status."
      end

      unless @assignment.grade_item.nil?
        @assignment.grade_item.visible = @assignment.released
        @assignment.grade_item.save
      end
    end
      
    if @assignment.quiz.nil?  
      redirect_to :action => 'index', :course => @course, :assignment => @assignment
    else
      redirect_to :controller => '/instructor/results', :action => 'quiz', :course => @course, :assignment => @assignment
    end
  end
  
  def rollback
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    # make sure the student exists
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    @turnins = Array.new
    if @assignment.team_project
      team = @course.team_for_user( @student.id )
      @turnins = UserTurnin.find(:all, :conditions => ["project_team_id=? and assignment_id=?", team.id, @assignment.id ], :order => "position DESC" )
    else
      # get turn-in sets
      @turnins = UserTurnin.find(:all, :conditions => ["user_id=? and assignment_id=?", @student.id, @assignment.id ], :order => "position DESC" )
    end
    @current_turnin = @turnins[0] rescue @current_turnin = nil
   
    if @current_turnin.user_turnin_files.size == 1
      @current_turnin.destroy
    else
      flash[:badnotice] = "Can not rollback the current turn-in set for this student, it is not empty."
    end
    
    redirect_to :action => 'view_student', :course => @course, :assignment => @assignment, :id => @student
  end
  
  def unfinalize
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    # make sure the student exists
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    @turnins = Array.new
    if @assignment.team_project
      team = @course.team_for_user( @student.id )
      @turnins = UserTurnin.find(:all, :conditions => ["project_team_id=? and assignment_id=?", team.id, @assignment.id ], :order => "position DESC" )
    else
      # get turn-in sets
      @turnins = UserTurnin.find(:all, :conditions => ["user_id=? and assignment_id=?", @student.id, @assignment.id ], :order => "position DESC" )
    end
    @current_turnin = @turnins[0] rescue @current_turnin = nil
    
    unless @current_turnin.nil?
      if @current_turnin.finalized || @current_turnin.sealed
        @current_turnin.finalized = false
        @current_turnin.sealed = false
        
        if @current_turnin.save
          flash[:notice] = "Reopened the most recent turn-in set."
        else
          flash[:badnotice] = "Error reopening turn-in set, please try again."
        end
      else
        flash[:notice] = "Most recent turn-in set is not sealed or finalized."
      end
    end
    redirect_to :action => 'view_student', :id => @student
  end
  
  def view_student
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    # make sure the student exists
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    @apply_to_team = false
    if @assignment.team_project
      @team = @course.team_for_user( @student.id )
      @apply_to_team = true unless @team.nil?
    end
    
    # get grade
    # load grades
    @grade_item = GradeItem.find(:first, :conditions => ["assignment_id = ?", @assignment.id] )
    if @grade_item
      @grade_entry = GradeEntry.find(:first, :conditions => ["grade_item_id=? and user_id=?", @grade_item.id, @student.id ] )
      unless @grade_entry
        @grade_entry = GradeEntry.new
      else
        ## if there is an existing item for this student, bias the apply to all to false
        @apply_to_team = false
      end
    end
    
    # get journals
    @journals = Array.new
    if !@assignment.team_project || @team.nil?
      # if this is not a team project, or they are not on a team, pull journals
      @journals = Journal.find(:all, :conditions => ["user_id=? and assignment_id=?", @student.id, @assignment.id ], :order => "start_time ASC" )
    else
      ## get journals for all team members
      @team_journals = Hash.new
      @team.team_members.each do |tm|
        @team_journals[tm.user.id] = Journal.find(:all, :conditions => ["user_id=? and assignment_id=?", tm.user.id, @assignment.id ], :order => "start_time ASC" )
      end
      
    end
   
    # get turn-in sets
    @turnins = Array.new
    if @assignment.team_project
      @turnins = UserTurnin.find(:all, :conditions => ["project_team_id=? and assignment_id=?", @team.id, @assignment.id ], :order => "position DESC" )
    else
      # get turn-in sets
      @turnins = UserTurnin.find(:all, :conditions => ["user_id=? and assignment_id=?", @student.id, @assignment.id ], :order => "position DESC" )
    end
    @current_turnin = @turnins[0] rescue @current_turnin = nil
    @display_turnin = @current_turnin
    
    if params[:ut]
      @turnins.each { |x| @display_turnin = x if x.id == params[:ut].to_i }
    end
    
    if @assignment.enable_journal
     if @assignment.journal_field.start_time && @assignment.journal_field.end_time
      # calculate time
      elapsed = 0;
      @journals.each do |journal|
        elapsed += journal.end_time - journal.start_time - journal.interruption_time*60
      end
      elapsed = (elapsed / 60).truncate #down to minutes
      @minutes = elapsed % 60
      elapsed -= @minutes

      @days = (elapsed / 1440).truncate
      elapsed -= @days * 1440

      @hours = (elapsed / 60).truncate
     end
    end 
    
    count_todays_turnins( @app["turnin_limit"].to_i )
    
    # load any existing rubric entries
    @rubric_entry_map = Hash.new
    user_rubrics = RubricEntry.find(:all, :conditions => ["assignment_id = ? and user_id=?", @assignment.id, @student.id])
    @assignment.rubrics.each do |rubric|
      this_rubric_entry = nil
      user_rubrics.each do |user_rubric|
        this_rubric_entry = user_rubric if user_rubric.rubric_id == rubric.id  
      end  
      # if there isn't a rubric entry for this, we'll create one now
      if this_rubric_entry.nil?
        this_rubric_entry = create_rubric_entry( @assignment, @student, rubric )
        this_rubric_entry.above_credit = false
        this_rubric_entry.full_credit = false
        this_rubric_entry.partial_credit = false
        this_rubric_entry.no_credit = false
        # this save may not work -- but it should, if it fails, it is for a duplicate key issue, race condition
        this_rubric_entry.save rescue true == true
      end      
      
      @rubric_entry_map[rubric.id] = this_rubric_entry
    end
    
    
    @title = "#{@student.display_name} (#{@student.uniqueid}) - #{@assignment.title}"
    
  end
  
  def submit_grade
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @student = User.find( params[:id] )
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    ## see if this is a team assignment & applying to all
    @team = nil
    @apply_to_team = params[:apply_to_team].to_s.eql?('true')
    if @assignment.team_project && @apply_to_team
      @team = @course.team_for_user( @student.id )
    end
    
    if params[:commit].index("Skip and").nil?
      # get grade
      # load grades
      @grade_item = GradeItem.find(:first, :conditions => ["assignment_id = ?", @assignment.id] )
      if @grade_item

        entries = Hash.new
        rubric_entries = Hash.new

        if @team.nil?
          entries[@student.id] = GradeEntry.find(:first, :conditions => ["grade_item_id=? and user_id=?", @grade_item.id, @student.id ] )
          rubric_entries[@student.id] = Hash.new

          user_rubric_entries = RubricEntry.find(:all, :conditions => ["assignment_id = ? and user_id=?", @assignment.id, @student.id])
          user_rubric_entries.each { |x| rubric_entries[@student.id][x.rubric_id] = x }
        else
          # load for all team members
          @team.team_members.each do |tm|
            entries[tm.user.id] = GradeEntry.find(:first, :conditions => ["grade_item_id=? and user_id=?", @grade_item.id, tm.user.id ] )
            rubric_entries[tm.user.id] = Hash.new

            user_rubric_entries = RubricEntry.find(:all, :conditions => ["assignment_id = ? and user_id=?", @assignment.id, tm.user.id])
            user_rubric_entries.each { |x| rubric_entries[tm.user.id][x.rubric_id] = x }
          end
        end

        # for each entry save
        @success = true
        @deleted = false
        GradeEntry.transaction do
          # process all the grade entries
          entries.keys.each do |key|
            grade_entry = entries[key]

            if grade_entry
              grade_entry.update_attributes( params[:grade_entry] )
            else
              grade_entry = GradeEntry.new( params[:grade_entry] )
              grade_entry.course = @course
              grade_entry.user_id = key.to_i
              grade_entry.grade_item = @grade_item
            end

            grade_entry.points = 0 if grade_entry.points.to_s.eql?('')

            if grade_entry.points < 0
              grade_entry.destroy
              grade_entry = nil
              @deleted= true
            end

            # since the key here is our user ID we can also update the rubrics in the same way
            # for each rubric for this user (key)
            @assignment.rubrics.each do |rubric|
               rubric_entry = rubric_entries[key][rubric.id]
               if rubric_entry.nil?
                 rubric_entry = RubricEntry.new
                 rubric_entry.assignment = @assignment
                 rubric_entry.user_id = key
                 rubric_entry.rubric = rubric
               end

               # update the full/partial/no credit selector
               rubric_entry.above_credit   = params["rubric_#{rubric.id}"].eql?("above")
               rubric_entry.full_credit    = params["rubric_#{rubric.id}"].eql?("full")
               rubric_entry.partial_credit = params["rubric_#{rubric.id}"].eql?("partial")
               rubric_entry.no_credit      = params["rubric_#{rubric.id}"].eql?("no")
               rubric_entry.comments       = params["rubric_#{rubric.id}_comments"]
               @success = rubric_entry.save && @success
            end

            @success = grade_entry.save && @success unless @deleted
          end
        end
      else 
        flash[:badnotice] = "Application error - there is not grade item for this assignment.  Set on up in the GradeBook."
      end

      if @deleted
        flash[:notice] = "Grade for '#{@student.display_name}' has been deleted for this assignment (Since no point value was entered)."
      elsif @success
        flash[:notice] = "Grade for '#{@student.display_name}' has been updated to '#{params[:grade_entry]['points']}' for this assignment."
      else
        flash[:badnotice] = "Error updating student grade - results not saved."
      end
    end
    
    
    student_id = @student.id
    begin
      unless params[:commit].index("Next Student").nil?
        ## get all students from the class, advance to the one after @student
        student_id = nil
        next_student = false
        @course.students.each do |student|
          if next_student 
            student_id = student.id
            next_student = false
          end
          
          if student.id == @student.id
            next_student = true
          end
        end
      end
    rescue
    end
    
    if @assignment.quiz.nil?  
      unless student_id.nil?
        redirect_to :action => 'view_student', :id => student_id
      else
        flash[:notice] = "#{flash[:notice]}<br/>Grade for the last student on the roster was saved, nothing to advance to."
        redirect_to :action => 'index', :id => nil
      end
    else
      if student_id.nil?
        redirect_to :controller => '/instructor/results', :action => 'quiz', :course => @course, :assignment => @assignment
      else
        redirect_to :controller => '/instructor/results', :action => 'for_student', :course => @course, :assignment => @assignment, :id => student_id
      end
    end
  end
  
  def grant
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    # make sure the student exists
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    @extension = @assignment.extension_for_user( @student )
    if @extension.nil? 
      @extension = Extension.new
      @extension.extension_date = @assignment.due_date
    end  
  end
  
  def update_grant
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    # make sure the student exists
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    # find the current extension
    extension = @assignment.extension_for_user( @student )
    if extension.nil?
      extension = Extension.new( params[:extension] )
      extension.assignment = @assignment
      extension.user = @student
    else
      extension.update_attributes(params[:extension])
    end
    
    if extension.save
      flash[:notice] = "#{@student.display_name} was granted an extension until #{extension.extension_date.to_formatted_s(:long)}"
      if @assignment.quiz
        redirect_to :controller => '/instructor/results', :action => 'quiz', :course => @course, :assignment => @assignment
      else
        redirect_to :action => nil, :controller => 'instructor/turnins', :course => @course, :assignment => @assignment, :id => nil
      end
    else
      redirect_to :action => 'grant', :course => @course, :assignment => @assignment, :id => @student
    end   
  end
  
  def revoke
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    # make sure the student exists
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    extension = @assignment.extension_for_user( @student )
    if ! extension.nil?
       extension.destroy
       flash[:notice] = "#{@student.display_name} extension has been revoked."
    end
    
    if @assignment.quiz
      redirect_to :controller => '/instructor/results', :action => 'quiz', :course => @course, :assignment => @assignment
    else
      redirect_to :action => nil, :controller => 'instructor/turnins', :course => @course, :assignment => @assignment, :id => nil
    end
  end
  
  def download_all_files
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    ## create temp file for the archive
    tf = TempFiles.new
    tf.filename = "#{@app['temp_dir']}/#{@user.uniqueid}_assignment_#{@assignment.id}_all_files.tar.gz"
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
        uts = UserTurnin.find(:first, :conditions => ["project_team_id=? and assignment_id=?", t.id, @assignment.id ], :order => "created_at desc" )
        FileUtils.mkdir_p( "#{temp_dir}#{file_tmp_dir}/#{t.team_id}" )
        unless uts.nil?
          dir = uts.get_team_dir("#{@app['external_dir']}", t )
          command = "cd #{dir}; cp -R * #{temp_dir}#{file_tmp_dir}/#{t.team_id}"
          result = `#{command} 2>&1`
        end
      end
    
    else
      students = @course.students
      # copy turnins
      students.each do |s|
        uts = UserTurnin.find(:first, :conditions => ["user_id=? and assignment_id=?", s.id, @assignment.id ], :order => "created_at desc" )
        FileUtils.mkdir_p( "#{temp_dir}#{file_tmp_dir}/#{s.uniqueid}" )
        unless uts.nil?
          dir = uts.get_dir("#{@app['external_dir']}")
          command = "cd #{dir}; cp -R * #{temp_dir}#{file_tmp_dir}/#{s.uniqueid}"
          result = `#{command} 2>&1`
        end
      end
    end
    
    
    #directory = @turnin.get_dir( @app['external_dir'] )
    #last_part = directory[directory.rindex('/')+1...directory.size]
    #first_part = directory[0...directory.rindex('/')]
    
    tar_cmd = "cd #{temp_dir}#{file_tmp_dir}; tar -czf #{tf.filename} *"
    #puts "#{tar_cmd}"
    result = `#{tar_cmd} 2>&1`
  
    if result.size > 0 
      flash[:badnotice] = "There was an error creating the download file, please try again later."
      redirect_to :action => 'index', :id => nil
      return
    end
  
    begin  
      send_file tf.filename, :filename => "#{@user.uniqueid}_assignment_#{@assignment.id}_all_files.tar.gz"
      rescue
        flash[:badnotice] = "There was an error creating the download file, please try again later."
        redirect_to :action => 'view_student', :id => @turnin.user_id
      
    end
    
    # cleanup 
    result = `cd #{temp_dir}; rm -r #{file_tmp_dir}`
  end
  
  def download_set
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @turnin = UserTurnin.find( params[:id] ) rescue @turnin = UserTurnin.new
    return unless turnin_for_assignment( @turnin, @assignment )
    
    tf = TempFiles.new
    tf.filename = "#{@app['temp_dir']}/#{@user.uniqueid}_assignment_#{@assignment.id}_turnin_#{@turnin.id}.tar.gz"
    tf.save_until = Time.now + 60*24*24
    tf.save
    
    if @assignment.team_project
      team = @turnin.project_team
      directory = @turnin.get_team_dir( @app['external_dir'], team )
    else
      directory = @turnin.get_dir( @app['external_dir'] )
    end
    last_part = directory[directory.rindex('/')+1...directory.size]
    first_part = directory[0...directory.rindex('/')]
    
    tar_cmd = "tar -C #{first_part} -czf #{tf.filename} #{last_part}"
    result = `#{tar_cmd} 2>&1`
    
    if result.size > 0 
      flash[:badnotice] = "There was an error creating the download file, please try again later."
      redirect_to :action => 'index', :id => nil
      return
    end
    
    begin  
      send_file tf.filename, :filename => "#{@user.uniqueid}_assignment_#{@assignment.id}_turnin_#{@turnin.id}.tar.gz"
    rescue
      flash[:badnotice] = "There was an error creating the download file, please try again later."
      redirect_to :action => 'view_student', :id => @turnin.user_id
    end   
    
  end
  
  def download_file
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @utf = UserTurninFile.find( params[:id] )  
    return unless turnin_file_downloadable( @utf )
    @turnin = @utf.user_turnin 
    return unless turnin_for_assignment( @turnin, @assignment )
    
    # get the file and download it :)
    if @assignment.team_project
      team = @turnin.project_team
      directory = @turnin.get_team_dir( @app['external_dir'], team )
    else
      directory = @turnin.get_dir( @app['external_dir'] )
    end
    
    # resolve file name
    relative_name = @utf.filename
    walker = @utf
    while walker.directory_parent > 0 
      walker = UserTurninFile.find( walker.directory_parent )
      relative_name = "#{walker.filename}/#{relative_name}"
    end
    
    filename = "#{directory}#{relative_name}"
    
    begin  
      send_file filename, :filename => @utf.filename
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt.  Please notify your system administrator if this problem continues."
      redirect_to :action => 'view_student', :course => @course, :assignment => @assignment, :id => @utf.user_id
    end
  end
  
  def file_comment
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @utf = UserTurninFile.find( params[:id] )  
    return unless turnin_file_downloadable( @utf )
    @turnin = @utf.user_turnin 
    return unless turnin_for_assignment( @turnin, @assignment )
    
    line_number = params[:line]
    inst_comments = params[:comments]
    
    comment = FileComment.find(:first, :conditions => ["user_turnin_file_id=? and line_number=?", @utf.id, line_number] ) rescue comment = nil
    if comment.nil?
      comment = FileComment.new
    end
    comment.user_turnin_file = @utf
    comment.line_number = line_number
    comment.user = @user
    comment.comments = inst_comments
    
    comment.save
    @line = line_number
    render :layout => false
  end
  
  def toggle_style_item
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @utf = UserTurninFile.find( params[:id] )  
    return unless turnin_file_downloadable( @utf )
    @turnin = @utf.user_turnin 
    return unless turnin_for_assignment( @turnin, @assignment )
    
    line_number = params[:line]
    style_item = params[:file_style]
    
    style = FileStyle.find( style_item.to_i ) rescue comment = nil
    
    style.suppressed = !style.suppressed
    
    style.save
    
    @line = line_number
    
    @styles = FileStyle.find( :all, :conditions => ["user_turnin_file_id = ? and begin_line = ?", @utf.id, @line] )
    
    render :layout => false
  end
  
  def toggle_gradable_override
    throw "error" unless load_course( params[:course] )
    throw "error" unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    throw "error" unless assignment_in_course( @course, @assignment )
    
    @student = User.find( params[:student] )
    throw "error" unless student_in_course( @course, @student )
    
    @utf = UserTurninFile.find( params[:id] )  
    @turnin = @utf.user_turnin
    throw "error" unless turnin_file_downloadable( @utf )
    throw "error" unless turnin_for_assignment( @turnin, @assignment )
    
    @utf.gradable_override = ! @utf.gradable_override
    @utf.save
    
    
    render :layout => false
  end
  
  def autograde_output
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @student = User.find( params[:student] )
    return unless student_in_course( @course, @student )
    
    # get turn-in sets
    if @assignment.team_project
      @team = @course.team_for_user( @student.id )
      @turnins = UserTurnin.find(:all, :conditions => ["project_team_id=? and assignment_id=?", @team.id, @assignment.id ], :order => "position DESC" )
    else
      @turnins = UserTurnin.find(:all, :conditions => ["user_id=? and assignment_id=?", @student.id, @assignment.id ], :order => "position DESC" )
    end
    
    @current_turnin = @turnins[0] rescue @current_turnin = nil
    @display_turnin = @current_turnin
    
    if @current_turnin.nil?
      flash[:badnotice] = "This student did not submit any files, so there are no IO test results to view."
      redirect_to :action => 'view_student', :course => @course, :assignment => @assignment, :id => @student
      return
    end
    
    return unless turnin_for_assignment( @current_turnin, @assignment ) 
    
    tag = "#{@course.id},#{@assignment.id},#{@student.id},#{@current_turnin.id}"
    @job = Bj.table.job.find(:first, :conditions => ["tag = ?", tag], :order => "submitted_at desc")
    if @job.nil?
      @job = Bj.table.job_archive.find(:first, :conditions => ["tag = ?", tag], :order => "submitted_at desc")
    end
    
    @title = "AutoGrade Output: #{@course.title}, #{@assignment.title}, #{@student.display_name}"
    render :layout => 'noright'
  end
  
  def view_io_tests
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @student = User.find( params[:student] )
    return unless student_in_course( @course, @student )
    
    # get turn-in sets
    if @assignment.team_project
      @team = @course.team_for_user( @student.id )
      @turnins = UserTurnin.find(:all, :conditions => ["project_team_id=? and assignment_id=?", @team.id, @assignment.id ], :order => "position DESC" )
    else
      @turnins = UserTurnin.find(:all, :conditions => ["user_id=? and assignment_id=?", @student.id, @assignment.id ], :order => "position DESC" )
    end
    
    @current_turnin = @turnins[0] rescue @current_turnin = nil
    @display_turnin = @current_turnin
    
    if @current_turnin.nil?
      flash[:badnotice] = "This student did not submit any files, so there are no IO test results to view."
      redirect_to :action => 'view_student', :course => @course, :assignment => @assignment, :id => @student
      return
    end
    
    return unless turnin_for_assignment( @current_turnin, @assignment )   
    
    # turnins
    @line_format = false 
    @line_format = true if params[:line].to_i == 1 rescue @line_format = false
    
    @student_io_check = Hash.new
    @student_io_check_lines = Hash.new
    @assignment.io_checks.each do |check|
       student_check = IoCheckResult.find(:first, :conditions => ["io_check_id = ? && user_turnin_id = ?", check.id, @current_turnin.id ] )
       unless student_check.nil?
         @student_io_check[check.id] = student_check
         
         @student_io_check_lines[check.id] = Hash.new
         @student_io_check_lines[check.id][:EXPECTED] = check.output.split("\n")
         @student_io_check_lines[check.id][:STUDENT] = student_check.output.split("\n")
         @student_io_check_lines[check.id][:DIFF] = student_check.diff_report.split("\n")
       end
    end
    
    @title = "AutoGrade Results: #{@course.title}, #{@assignment.title}, #{@student.display_name}"
    render :layout => 'noright'
  end
  
  def autograde_all
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @students = @course.students
    
    t = Time.now
    batch = "#{t.strftime( "%Y%m%d%H%M%S" )}u#{@user.id}"
    
    if @assignment.team_project
      teams = @course.project_teams
      teams.each do |team|
        @turnins = UserTurnin.find(:all, :conditions => ["project_team_id=? and assignment_id=?", team.id, @assignment.id ], :order => "position DESC" )
        @current_turnin = @turnins[0] rescue @current_turnin = nil

        if ! @current_turnin.nil?
          queue = GradeQueue.new
          queue.user = @user
          queue.assignment = @assignment
          queue.user_turnin = @current_turnin
          queue.batch = batch
          queue.save
          AutoGradeHelper.schedule_job( queue.id )
        end
      end
    
    else
      @students.each do |student|
        @turnins = UserTurnin.find(:all, :conditions => ["user_id=? and assignment_id=?", student.id, @assignment.id ], :order => "position DESC" )
        @current_turnin = @turnins[0] rescue @current_turnin = nil

        if ! @current_turnin.nil?
          queue = GradeQueue.new
          queue.user = @user
          queue.assignment = @assignment
          queue.user_turnin = @current_turnin
          queue.batch = batch
          queue.save
          AutoGradeHelper.schedule_job( queue.id )
        end
      end
    end
      
    flash[:notice] = "I've queued up grading requests for all students in #{@course.title} for the assignment '#{@assignment.title}.'   This may take a while... please be patient."
      
    redirect_to :controller => '/wait', :action => 'for_all', :course => @course, :assignment => @assignment, :student => nil, :id => batch
  end
  
  def change_main
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    # make sure the student exists
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'index'
    end
    
    utf = UserTurninFile.find( params[:tif] ) 
    unless utf.main_candidate
      flash[:badnotice] = "The selected file '#{utf.filename}' does not contain a main function."
      return  
    end 
    
    if utf.user_turnin.assignment_id == @assignment.id
      UserTurnin.transaction do
         
         utf.user_turnin.user_turnin_files.each do |this_file|
           if this_file.id == utf.id
             this_file.main = true
           else
             this_file.main = false 
           end
           this_file.save
         end
      end
      
      flash[:notice] = "'#{utf.filename}' will be the main file for grading."
      
    else
      flash[:badnotice] = "Selected file is not in the current turnin set."
    end
    
    redirect_to :controller => 'instructor/turnins', :action => 'view_student', :course => @course, :assignment => @assignment, :id => @student
  end  
  
  
  
  def io_retest
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @student = User.find( params[:student] )
    return unless student_in_course( @course, @student )
    
    # get turn-in sets
    if @assignment.team_project
      @team = @course.team_for_user( @student.id )
      @turnins = UserTurnin.find(:all, :conditions => ["project_team_id=? and assignment_id=?", @team.id, @assignment.id ], :order => "position DESC" )
    else
      @turnins = UserTurnin.find(:all, :conditions => ["user_id=? and assignment_id=?", @student.id, @assignment.id ], :order => "position DESC" )
    end
    @current_turnin = @turnins[0] rescue @current_turnin = nil
    return unless turnin_for_assignment( @current_turnin, @assignment )   
    
    # submit for autograde
    queue = GradeQueue.new
    queue.user = @user
    queue.assignment = @assignment
    queue.user_turnin = @current_turnin
    if queue.save
      AutoGradeHelper.schedule_job( queue.id )
      ## need to do a different rediect
      redirect_to :controller => '/wait', :action => 'grade', :id => queue.id, :course => nil, :assignment => nil, :student => nil
      return
      
    else
      flash[:badnotice] = "There was an error submitting this assignment to the AutoGrade queue, please try again."
      redirect_to :course => @course, :assignment => @assignment, :student => @student, :action => 'view_io_tests'
    end
    
  end
  
  def view_file
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_student_files', 'ta_grade_individual' )
    
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @student = User.find( params[:student] )
    return unless student_in_course( @course, @student )
    
    @utf = UserTurninFile.find( params[:id] )  
    return unless turnin_file_downloadable( @utf )
    @turnin = @utf.user_turnin 
    return unless turnin_for_assignment( @turnin, @assignment )
    
    @expand = nil
    if params[:expand].eql?('true')
      @expand = true
    end
    
    if @assignment.team_project
      team = @turnin.project_team
      directory = @turnin.get_team_dir( @app['external_dir'], team )
    else
      directory = @turnin.get_dir( @app['external_dir'] )
    end
    
    # resolve file name
    relative_name = @utf.filename
    walker = @utf
    while walker.directory_parent > 0 
      walker = UserTurninFile.find( walker.directory_parent )
      relative_name = "#{walker.filename}/#{relative_name}"
    end
    
    # fix double slashes
    relative_name.gsub!(/\/\//,"/")
    filename = "#{directory}#{relative_name}"
    
    @title = "#{relative_name} - #{@student.display_name} (#{@student.uniqueid}) - #{@assignment.title}"
    
    begin      
      @lines = FileManager.format_file( @app['enscript_command'], filename, @utf.extension )
      
      if @utf.extension.eql?("java")
        @lines.each do |line| 
          public_index = line.index('public') 
          static_index = line.index('static') 
          void_index = line.index('void') 
          main_index = line.index('main') 
          #puts "p:#{public_index} s:#{static_index} v:#{void_index} m:#{main_index} line:#{line}"
          # line must contain all of these
          if( !public_index.nil? && !static_index.nil? && !void_index.nil? && !main_index.nil? &&
              static_index > public_index && void_index > public_index &&
              main_index > public_index && main_index > static_index && main_index > void_index )
            @java_main = true
            break
          end
        end
      end

      @comments = @utf.file_comments_hash
      @styles = @utf.file_style_hash( true )
      
    rescue
      flash[:badnotice] = "Error loading selected file.  Please contact your system administrator."
      redirect_to :action => 'view_student', :course => @course, :assignment => @assignment, :student => nil, :id => @student
      return
    end
    
    ## Execution interception
    if @java_main && params[:execute_java].eql?('true')
      absolute_directory = filename[0...filename.rindex('/')]
      base_file = filename[filename.rindex('/')+1..-1]
      
      @display_java_execute = true
      
      pl = ProgrammingLanguage.find_by_extension( @utf.extension )
      if pl.nil?
        flash[:badnotice] = "There was an error loading the programming language runtime for this language."
      else
        runner = SimpleProgramRunner.new( pl, absolute_directory, base_file, logger )
        @compile_out = runner.compile()
        @compile_success = runner.did_compile?()
        if @compile_success
          @command_line_arguments = params[:command_line_arguments]
          @standard_in = params[:standard_in]
          @execute_out = runner.execute( params[:command_line_arguments], params[:standard_in] )
          
          @execute_out_html = ""
          0.upto(@execute_out.size-1) do |i|
            str = @execute_out[i...i+1]
            if str.eql?("\n")
              @execute_out_html << "<br/>"
            elsif str.eql?(" ")
              @execute_out_html << "&nbsp;"
            else 
              @execute_out_html << str
            end
          end
        end
      end
    end
    
    render :layout => 'noright'
  end
  
  def diff_count
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual', 'ta_view_student_files', 'ta_grade_individual' )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    if params['extension'].nil?
      flash[:notice] = "No extension selected".
      redirect_to :action => 'index', :course => @course, :assignment => @assignment, :id => nil
    end
    
    # load the students
    @students = @course.students
    
    @apply_to_team = false
    if @assignment.team_project
      @apply_to_team = true 
      @teams = @course.project_teams
    end
    
    @files_to_check = Hash.new
    
    if @apply_to_team
      ### get files for each team
      @teams.each do |team|
        turnin = UserTurnin.find(:first, :conditions => ["project_team_id=? and assignment_id=?", team.id, @assignment.id ], :order => "position DESC" )
        unless turnin.nil?
          directories = Hash.new
          turnin.user_turnin_files.each do |utf|
            directories[utf.id] = utf if utf.directory_entry?
          end
          directory = turnin.get_team_dir( @app['external_dir'], team ) 
          
          turnin.user_turnin_files.each do |file|
            unless file.extension.nil?
              if file.extension.downcase.eql?( params['extension'].downcase )
                @files_to_check[file.id] = "#{directory}#{file.full_filename( directories )}"
              end
            end
          end
        end
     
      end
      
    else
      ### get files for each student
      @students.each do |student|
        turnin = UserTurnin.find(:first, :conditions => ["user_id=? and assignment_id=?", student.id, @assignment.id ], :order => "position DESC" )
        unless turnin.nil?
          directories = Hash.new
          turnin.user_turnin_files.each do |utf|
            directories[utf.id] = utf if utf.directory_entry?
          end
          directory = turnin.get_dir( @app['external_dir'] ) 
          
          turnin.user_turnin_files.each do |file|
            unless file.extension.nil?
              if file.extension.downcase.eql?( params['extension'].downcase )
                @files_to_check[file.id] = "#{directory}#{file.full_filename( directories )}"
              end
            end
          end
        end
  
      end
      
    end
    
    ## for display
    @textfiles = FileManager.text_extension_map.sort
    @diffsize = diff_arr
    
    @count = params['diffcount'].to_i rescue count = 10
    @differences = DiffCount.assignment_diff( @app['diff_command'], @app['wc_command'], @files_to_check, @count )


  end
  
  def sidebyside
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_grade_individual', 'ta_view_student_files', 'ta_grade_individual' )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    
    @utf1 = UserTurninFile.find( params['file1'].to_i ) rescue utf1 = nil
    @utf2 = UserTurninFile.find( params['file2'].to_i ) rescue utf2 = nil
    
    if @utf1.nil? || @utf2.nil? || @utf1.user_turnin.assignment_id != @assignment.id || @utf2.user_turnin.assignment_id != @assignment.id
      flash[:notice] = "Invalid files requested"
      redirect_to :action => 'index', :course => @course, :assignment => @assignment, :id => nil
      return
    end
    
    
    @turnin1 = @utf1.user_turnin
    @turnin2 = @utf2.user_turnin
    
    if @assignment.team_project == true
      ## load the directories
      @directories1 = Hash.new
      @turnin1.user_turnin_files.each do |utf|
        @directories1[utf.id] = utf if utf.directory_entry?
      end
      @directory1 = @turnin1.get_team_dir( @app['external_dir'], @turnin1.project_team )
 
      @directories2 = Hash.new
      @turnin2.user_turnin_files.each do |utf|
        @directories2[utf.id] = utf if utf.directory_entry?
      end
      @directory2 = @turnin2.get_team_dir( @app['external_dir'], @turnin2.project_team )
    
    else
      ## load the directories
      @directories1 = Hash.new
      @turnin1.user_turnin_files.each do |utf|
        @directories1[utf.id] = utf if utf.directory_entry?
      end
      @directory1 = @turnin1.get_dir( @app['external_dir'] )
    
      @directories2 = Hash.new
      @turnin2.user_turnin_files.each do |utf|
        @directories2[utf.id] = utf if utf.directory_entry?
      end
      @directory2 = @turnin2.get_dir( @app['external_dir'] )
    end
    
    ## now we can grab the files
    filename1 = "#{@directory1}#{@utf1.full_filename( @directories1 )}"
    filename2 = "#{@directory2}#{@utf2.full_filename( @directories2 )}"
    
    @lines1 = Array.new
    File.open(filename1, "r") do |file|
      while (line = file.gets)
        @lines1 << line
      end
    end
    
    @lines2 = Array.new
    File.open(filename2, "r") do |file|
      while (line = file.gets)
        @lines2 << line
      end
    end
    
    @changesets = Array.new
    diffs = TextDiff.run_diff( @lines1, @lines2 )
    diffs.each do |da|
      da.each do |change| 
        @changesets << change
      end
    end
  
    @max = @lines1.size
    @max = @lines2.size if @lines2.size > @lines1.size
    
  end
  
  
  ## BEGIN PRIVATE UTILITY METHODS
private  

  def diff_arr
    return [5,10,15,25,50,75,100,150,500]
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "Turins - #{@assignment.title}"
  end
  
  def assignment_in_course( course, assignment )
    unless course.id == assignment.course.id
      redirect_to :controller => '/instructor/index', :course => course
      flash[:notice] = "Requested assignment could not be found."
      return false
    end
    true
  end
  
  def turnin_for_assignment( turnin, assignment )
    unless turnin.assignment_id == assignment.id
      flash[:badnotice] = "The requested turn-in does not belong to this assignment."
      redirect_to :action => 'index', :assignment => assignment.id
    end
    true    
  end
  
  def turnin_file_downloadable( tif )
    if tif.directory_entry
      flash[:badnotice] = "Individual turn-in directories can not be downloaded"
      redirect_to :action => 'index', :assignment => tif.assignment_id
      return false
    end
    true
  end
  
  def count_todays_turnins( max = 3 )
    now = Time.now
    begin_time = Time.local( now.year, now.mon, now.day, 0, 0, 0 )
    end_time = begin_time + 60*60*24 # plus a day
    @today_count = UserTurnin.count( :conditions => [ "assignment_id = ? and user_id = ? and finalized = ? and updated_at >= ? and updated_at < ?", @assignment.id, @student.id, true, begin_time, end_time ] )
    @remaining_count = max - @today_count 
    @remaining_count = 0 if @remaining_count < 0
  end
  
  def create_rubric_entry( assignment, student, rubric )
    this_rubric_entry = RubricEntry.new
    this_rubric_entry.assignment = assignment
    this_rubric_entry.user = student
    this_rubric_entry.rubric = rubric
    return this_rubric_entry
  end
  
end
