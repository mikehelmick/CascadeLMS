class ProgramController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_program_manager
  
  def index
    set_tab
  end
  
  def outcomes
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    set_tab(@program)
    @breadcrumb.text = "#{@program.title} - Outcomes"
    
    @program_outcome = ProgramOutcome.new
  end
  
  def save_outcome
    return unless load_program( params[:program] )
    return unless allowed_to_manage_program( @program, @user )    
    
    @program_outcome = ProgramOutcome.new(params[:program_outcome])
    @program_outcome.program = @program
    
     if @program_outcome.save
        set_highlight( "outcome_#{@program_outcome.id}" )
        flash[:notice] = 'New outcome has been saved'
        redirect_to :action => 'outcomes', :id => @program
      else
        render :action => 'outcomes', :id => @program
      end
    
  end
  
  def edit
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @program_outcome = ProgramOutcome.find params['outcome'] rescue @program_outcome = ProgramOutcome.new
    return unless outcome_for_program( @program, @program_outcome )
    set_tab(@program)
    @breadcrumb.text = 'Edit Program Outcome'
  end

  def update_outcome
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @program_outcome = ProgramOutcome.find params['outcome'] rescue @program_outcome = ProgramOutcome.new
    return unless outcome_for_program( @program, @program_outcome )  
    
    if @program_outcome.update_attributes(params[:program_outcome])
      flash[:notice] = 'Outcome was successfully updated.'
      set_highlight( "outcome_#{@program_outcome.id}" )
      redirect_to :action => 'outcomes', :id => @program
    else
      render :action => 'edit'
    end
    
  end
  
  def destroy
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @program_outcome = ProgramOutcome.find params['outcome'] rescue @program_outcome = ProgramOutcome.new
    return unless outcome_for_program( @program, @program_outcome )
    
    @program_outcome.destroy
    flash[:notice] = 'Program Outcome Deleted'
    redirect_to :action => 'outcomes', :id => @program
  end
  
  def sort
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    ProgramOutcome.transaction do
      @program.program_outcomes.each do |outcome|
        outcome.position = params['outcome-order'].index( outcome.id.to_s ) + 1
        outcome.save
      end
    end
        
    render :nothing => true
  end
  
  def users
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    @managers = @program.managers
    @auditors = @program.auditors
    set_tab(@program)
    @breadcrumb.text = 'Program Users'
  end

  def search
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    st = params[:searchterms].downcase
    if st.length >= 2
      sv = "%#{st}%"
      @users = User.find(:all, :conditions => ["(instructor=? or admin=? or auditor=? or program_coordinator=?) and (LOWER(uniqueid) like ? or LOWER(first_name) like ? or LOWER(last_name) like ? or LOWER(preferred_name) like ?)", true, true, true, true, sv, sv, sv, sv ], :order => "uniqueid asc")
    else
      @invalid = true
    end
  
    render :layout => false
  end
 
  def deluser
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @utype = params[:type]
    @program.programs_users.each do |u|
      if u.user_id.to_i == params[:user].to_i
        #puts "found correct user: #{u.user}"
        u.program_manager = false if @utype.eql?('manager')
        u.program_auditor = false if @utype.eql?('auditor')
        if u.any_user?
          u.save
        else
          u.destroy
        end
        @program.save
      end
    end
    
    render :nothing => true
  end
  
  def adduser
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    
    @utype = params[:type]
    added = false
    @program.programs_users.each do |u|
      if u.user_id.to_i == params[:user].to_i
        u.program_manager = true if @utype.eql?('manager') && (u.user.instructor || u.user.admin || u.user.program_coordinator)
        u.program_auditor = true if @utype.eql?('auditor') && (u.user.instructor || u.user.admin || u.user.program_coordinator || u.user.auditor)
        u.save
        @program.save
        added = true
      end
    end
    
    unless added
      p = ProgramsUser.new
      user = User.find(params[:user])
      p.program = @program
      p.user = user
      p.program_manager = false
      p.program_manager = true if @utype.eql?('manager') && (user.instructor || user.admin || user.program_coordinator)
      p.program_auditor = true if @utype.eql?('auditor') && (user.instructor || user.admin || user.program_coordinator || user.auditor)
      @program.programs_users << p
      @program.save   
    end
    
    @users = @program.managers if @utype.eql?('manager')
    @users = @program.auditors if @utype.eql?('auditor')
    
    render :layout => false, :partial => 'userlist', :locals => {:users => @users, :program => @program, :utype => @utype}
  end

  def templates
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    set_tab(@program)
    @breadcrumb.text = 'Course Templates'

    @course_templates = @program.course_templates.sort do |a,b|
      rtn = a.title <=> b.title
      if rtn == 0 
         a.start_date <=> b.start_date
      else
         rtn
      end
    end
  end
  
  def create_template
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @course_template = CourseTemplate.new(params[:course_template])
    
    if @course_template.save
        @course_template.programs << @program
        @course_template.save
      
        flash[:notice] = 'New course template was saved.'
        set_highlight( "course_template_#{@course_template.id}" )
        redirect_to :action => 'templates', :id => @program  
    else
        @course_templates = @program.course_templates
        render :action => 'templates'
    end
  end
  
  def edit_template
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    
    @all_programs = Program.find(:all, :order => 'title asc')  
    set_tab(@program)
    @breadcrumb.text = 'Edit Course Template'   
  end

  def update_template
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
   
    @all_programs = Program.find(:all, :order => 'title asc')
   
    CourseTemplate.transaction do
        @course_template.update_attributes( params[:course_template] )
        @course_template.programs.clear
        @course_template.save
        @all_programs.each do |program|
           @course_template.programs << program unless params["program_#{program.id}"].nil? 
        end
        @course_template.save
        
        flash[:notice] = 'Course template updated.'
        set_highlight( "course_template_#{@course_template.id}" )
        redirect_to :action => 'templates', :id => @program
        return
    end
    render :action => 'edit_template', :id => @program, :template => params[:template]
  end
  
  def template_outcomes
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    
    set_tab(@program)
    @breadcrumb.text = "Outcomes for '#{@course_template.title}'"  
  end
  
  def new_outcome
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    
    @course_template_outcome = CourseTemplateOutcome.new
    
    set_tab(@program)
    @breadcrumb.text = "Outcomes for Template '#{@course_template.title}'"
  end
  
  def create_course_template_outcome
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )    
    
    @course_template_outcome = CourseTemplateOutcome.new(params[:course_template_outcome])
    @course_template_outcome.course_template = @course_template
    @course_template_outcome.parent = params[:parent].to_i
    
    # find out what position this one should be
    at_level = @course_template.extract_outcome_by_parent( @course_template.course_template_outcomes, @course_template_outcome.parent ) 
    next_position = 1
    next_position = at_level[-1].position + 1 if at_level.length > 0
    @course_template_outcome.position = next_position
    
    # find the program outcomes that map
    program_outcomes = load_program_outcomes_for_template( @course_template )
    
    CourseTemplateOutcome.transaction do 
      if @course_template_outcome.save
        read_program_outcome_mappings_from_params( @course_template_outcome, program_outcomes, params )
        @course_template_outcome.save

        set_highlight( "course_template_outcome_#{@course_template_outcome.id}" )
        flash[:notice] = 'New course template outcome has been saved.'
        redirect_to :action => 'template_outcomes', :id => @program, :template => @course_template
      else
        render :action => 'new_outcome', :id => @program, :template => @course_template
      end
    end
  end
  
  def edit_template_outcome
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )

    set_tab(@program)

    @course_template_outcome = CourseTemplateOutcome.find(params[:outcome])
    return unless outcome_in_template( @course_template_outcome, @course_template )
  end
  
  def update_template_outcome
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    @course_template_outcome = CourseTemplateOutcome.find(params[:outcome])
    return unless outcome_in_template( @course_template_outcome, @course_template )
    
    # first - pull the outcome text
    @course_template_outcome.outcome = params[:course_template_outcome][:outcome]
    
    old_parent = @course_template_outcome.parent
    new_parent = params[:parent].to_i
    
    # pre-load the possible program outcomes
    program_outcomes = load_program_outcomes_for_template( @course_template )
    
    CourseTemplateOutcome.transaction do
      @course_template_outcome.clear_program_outcome_mappings
     read_program_outcome_mappings_from_params( @course_template_outcome, program_outcomes, params )
      @course_template_outcome.save
     
      
      # if hierarchy is changing - we have to recalculate both the old parent's child ordering
      # and the new parent's child ordering
      if old_parent != new_parent 
        
        position = 1
        @course_template.extract_outcome_by_parent( @course_template.course_template_outcomes, old_parent ).each do |outcome|
          if outcome.id != @course_template_outcome.id
            outcome.position = position
            position = position.next
            # update
            outcome.save
          end
        end
        
        position = 1
        @course_template.extract_outcome_by_parent( @course_template.course_template_outcomes, new_parent ).each do |outcome|
          if outcome.id != @course_template_outcome.id
            outcome.position = position
            position = position.next
            # update
            outcome.save
          end
        end
        
        # update record being edited
        @course_template_outcome.position = position
        @course_template_outcome.parent = new_parent
        
      end
      
      
      @course_template_outcome.save
      
      flash[:notice] = 'Your outcome changes have been saved.'
      return redirect_to( :action => 'template_outcomes', :id => @program, :template => @course_template )
    end
    render :action => 'edit_template_outcome', :id => @program, :template => @course_template, :outcome => @course_template_outcome
    
  end
  
  def reorder_template_outcome
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    @course_template_outcome = CourseTemplateOutcome.find(params[:outcome])
    return unless outcome_in_template( @course_template_outcome, @course_template )

    # get the outcomes at this level
    @course_template_outcomes = @course_template.extract_outcome_by_parent( @course_template.course_template_outcomes, @course_template_outcome.parent ) 
    @parent = @course_template_outcome.parent
    
    @parent_outcome = CourseTemplateOutcome.find(@parent) if @parent != -1 rescue @parent_outcome = nil
  end
  
  def sort_template_outcomes
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    
    # get the outcomes at this level
    @course_template_outcomes = @course_template.extract_outcome_by_parent( @course_template.course_template_outcomes, params[:parent].to_i ) 
    CourseTemplateOutcome.transaction do
      @course_template_outcomes.each do |outcome|
        outcome.position = params['outcome-order'].index( outcome.id.to_s ) + 1
        outcome.save
      end
    end
    
    render :nothing => true    
  end
  
  def destroy_template_outcome
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    @course_template_outcome = CourseTemplateOutcome.find(params[:outcome])
    return unless outcome_in_template( @course_template_outcome, @course_template )
    
    children = @course_template_outcome.child_outcomes
    
    CourseTemplateOutcome.transaction do
      if children.length > 0
        parents_children = @course_template.extract_outcome_by_parent( @course_template.course_template_outcomes, @course_template_outcome.parent )
        position = parents_children.length + 1
        
        children.each do |child|
          child.parent = @course_template_outcome.parent
          child.position = position
          position = position.next
          child.save
        end       
      end
      
      @course_template_outcome.destroy
    end
    
    
    redirect_to :action => 'template_outcomes', :id => @program, :template => @course_template   
  end
  
  def clone_template
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    
    CourseTemplate.transaction do 
      # easy part - copy the template
      @new_template = CourseTemplate.new
      @new_template.title = "#{@course_template.title} - COPY"
      @new_template.start_date = "#{@course_template.start_date} - COPY"
      @new_template.save
      
      # make the same program mappings
      @course_template.programs.each do |program|
        @new_template.programs << program
      end
      @new_template.save
      
      parent_map = Hash.new
      parent_map[-1] = -1
      # hard part - copy all the objectives
      @course_template.ordered_outcomes.each do |copy_outcome|
        new_outcome = CourseTemplateOutcome.new
        new_outcome.outcome = copy_outcome.outcome
        new_outcome.position = copy_outcome.position
        new_outcome.parent = parent_map[copy_outcome.parent]
        new_outcome.save
        
        copy_outcome.program_outcomes.each do |outcome_program|
          new_outcome.program_outcomes << outcome_program
        end
        new_outcome.save
        
        parent_map[copy_outcome.id] = new_outcome.id
        
        @new_template.course_template_outcomes << new_outcome
      end
      
      @new_template.save
      
      flash[:notice] = "Course template clone succeeded.  You should edit the name to reflect the new course title or start date."
      redirect_to :action => 'template_outcomes', :id => @program, :template => @new_template
      return
    end
    
    flash[:badnotice] = "Course template clone failed."
    redirect_to :action => 'templates', :id => @program
  end
  
  def approve
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    
    @course_template.approved = true
    
    if @course_template.save
      flash[:notice] = "Course template was approved."
      redirect_to :action => 'templates', :id => @program
    else
      flash[:badnotice] = "There was an error approving the course template."
      redirect_to :action => 'templates', :id => @program     
    end    
  end
  
  def delete_template
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    
    if @course_template.destroy
      flash[:notice] = "Course template was deleted."
      redirect_to :action => 'templates', :id => @program
    else
      flash[:badnotice] = "There was an error deleting the course template."
      redirect_to :action => 'templates', :id => @program     
    end
  end
  
  def toggle_api_flag
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    
    @program.enable_api = ! @program.enable_api
    @program.save
    
    flash[:notice] = "Public API setting changed for #{@program.title}"
    redirect_to :controller => '/program', :action => nil, :id => nil
  end
  
  def courses
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )

    @current_term = Term.find(params[:term]) rescue @current_term = Term.find_current
    @terms = Term.find(:all, :order => 'term desc')
    
    @courses = Course.find_by_sql(["select * from courses left join (courses_programs) on (courses.id = courses_programs.course_id) where courses.term_id = ? and courses_programs.program_id = ? order by title asc;", @current_term.id, @program.id])
    set_tab(@program)
    
    render :layout => 'noright'
  end
  
  def view_course_outcomes
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    
    render :layout => 'noright'
  end
  
  
  def view_course_template_to_program_outcomes
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_template( params[:template] )
    return unless template_in_program( @course_template, @program )
    
    @numbers = load_outcome_numbers( @course_template )
    @course = @course_template ## For shared rendering
    
    @title = "'#{@course_template.title}' (#{@course_template.start_date}) Outcomes to Program Outcomes Report"    
    respond_to do |format|
        format.html { 
          set_tab(@program)
          render
        }
        format.csv  { 
          response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
          response.headers['Content-Disposition'] = "attachment; filename=#{@course_template.title}_course_template_outcomes_report.csv"
          render :layout => 'noright' 
        }
    end   
  end
  
  
  def view_course_to_program_outcomes
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    
    @numbers = load_outcome_numbers( @course )
    
    @title = "'#{@course.title}' Outcomes to Program Outcomes Report"    
    respond_to do |format|
        format.html { render :layout => 'noright' }
        format.csv  { 
          response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
          response.headers['Content-Disposition'] = "attachment; filename=#{@course.short_description}_course_outcomes_report.csv"
          render :layout => 'noright' 
        }
        
    end
  end
  
  def view_course_rubrics_report
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    
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
  
  def surveys
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    
    load_surveys( @course.id )
    
    render :layout => 'noright'
  end
  
  def compare_surveys
    return unless load_program( params[:id] )
    return unless allowed_to_manage_program( @program, @user )
    return unless load_course( params[:course] )
    return unless course_in_program?( @course, @program )
    
    error_url = url_for(:action => 'surveys', :id => @program, :course => @course)
    entry_exit_survey_compare(error_url)
  end
  
private

  def course_in_program?( course, program )
    if course.mapped_to_program?( program.id )
      return true
    end
    
    flash[:badnotice] = "Invalid course requested."
    redirect_to :controller => 'program', :action => nil, :id => nil, :template => nil 
    return false
  end
  
  def set_tab(program = nil)
    @title = "Program Management - Accreditation Tracking"
    @tab = 'programs'
    
    if (program.nil?)
      @breadcrumb = Breadcrumb.new()
      @breadcrumb.text = 'Programs'
      @breadcrumb.link = url_for(:action => 'index')
    else
      @breadcrumb = Breadcrumb.for_program(program)
    end
  end
  
  def read_program_outcome_mappings_from_params( course_template_outcome, program_outcomes, params )
    program_outcomes.each do |program_outcome|
      mapping_level = params["program_outcome_#{program_outcome.id}"]
      unless mapping_level.eql?('N')
        copo = CourseTemplateOutcomesProgramOutcome.new
        copo.course_template_outcome = course_template_outcome
        copo.program_outcome = program_outcome
        copo.level_some = mapping_level.eql?('S')
        copo.level_moderate = mapping_level.eql?('M')
        copo.level_extensive = mapping_level.eql?('E')
        course_template_outcome.course_template_outcomes_program_outcomes << copo
      end 
    end
  end
  
  def load_template( template_id, redirect = true )
    begin
      @course_template = CourseTemplate.find( template_id )
    rescue
      flash[:badnotice] = "Requested course template could not be found."
      redirect_to :controller => '/program' if redirect
      return false
    end    
  end
  
  def template_in_program( template, program, redirect = true )
    template.programs.each do |i|
      if i.id == program.id
        return true
      end
    end
    
    flash[:badnotice] = "The requested assignment could not be found."
    redirect_to :controller => 'assignments', :action => 'index', :course => @course if redirect
    return false
  end
  
  def load_program_outcomes_for_template( course_template )
    program_outcomes = Array.new
    course_template.programs.each do |program|
      program.program_outcomes.each do |prog_outcome|
        program_outcomes << prog_outcome
      end
    end
    return program_outcomes
  end
  
  def outcome_in_template( template_outcome, course_template, redirect = true )
    if template_outcome.course_template_id == course_template.id
      return true
    end
    
    flash[:badnotice] = "The requested outcome could not be found."
    redirect_to :controller => 'program', :action => 'template_outcomes', :id => @program, :template => @course_template if redirect
    return false
  end
  
end
