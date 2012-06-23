class Instructor::OutcomesController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
 
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
  
    # build list of available programs, filter out ones that this course is already a part of
    all_programs = Program.find(:all, :order => "title asc")
    @programs = Array.new
    all_programs.each do |program|
      add = true
      @course.programs.each do |course_program| 
        add = false if program.id == course_program.id
      end
      @programs << program if add
    end
    
    @surveys = Quiz.find(:all, :conditions => ["course_id = ? and entry_exit = ?", @course, true], :order => "id asc")
    
    set_title
  end
  
  def map_program
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    @program = Program.find(params[:program_id]) rescue @program = nil
    
    @course.programs << @program
    if @course.save
        set_highlight( "program_#{@program.id}" )
        flash[:notice] = 'New course to program mapping saved.'
        redirect_to :action => 'index', :course => @course
    else
      render :action => 'index', :course => @course
    end
  end
  
  def unmap_program
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    @program = Program.find(params[:program]) rescue @program = nil
   
    CoursesPrograms.delete_all(["course_id = ? and program_id = ?", @course.id, @program.id])
    
    render :nothing => true    
  end
  
  def edit
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    @course_outcome = CourseOutcome.find(params[:id])
    render :layout => 'noright'
    @title = "Edit Course Outcome for '#{@course.title}'"
  end
  
  def update_outcome
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    @course_outcome = CourseOutcome.find(params[:id])
    # first - pull the outcome text
    @course_outcome.outcome = params[:course_outcome][:outcome]
    
    old_parent = @course_outcome.parent
    new_parent = params[:parent].to_i
    
    # pre-load the possible program outcomes
    program_outcomes = load_program_outcomes( @course )
    
    CourseOutcome.transaction do
      @course_outcome.clear_program_outcome_mappings
      read_program_outcome_mappings_from_params( @course_outcome, program_outcomes, params )
      
      # if hierarchy is changing - we have to recalculate both the old parent's child ordering
      # and the new parent's child ordering
      if old_parent != new_parent 
        
        position = 1
        @course.extract_outcome_by_parent( @course.course_outcomes, old_parent ).each do |outcome|
          if outcome.id != @course_outcome.id
            outcome.position = position
            position = position.next
            # update
            outcome.save
          end
        end
        
        position = 1
        @course.extract_outcome_by_parent( @course.course_outcomes, new_parent ).each do |outcome|
          if outcome.id != @course_outcome.id
            outcome.position = position
            position = position.next
            # update
            outcome.save
          end
        end
        
        # update record being edited
        @course_outcome.position = position
        @course_outcome.parent = new_parent
        
      end
      
      
      @course_outcome.save
      
      flash[:notice] = 'Your outcome changes have been saved.'
      return redirect_to( :action => 'index', :course => @course )
    end
    render :action => 'edit', :course => @course, :id => params[:id]
  end
  
  def new
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    @course_outcome = CourseOutcome.new
    @title = "Create new Course Outcome for '#{@course.title}'"
    @breadcrumb = Breadcrumb.for_course(@course, true)
    @breadcrumb.outcomes = true
  end
  
  def create_outcome
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    @course_outcome = CourseOutcome.new(params[:course_outcome])
    @course_outcome.course = @course
    @course_outcome.parent = params[:parent].to_i
    
    # find out what position this one should be
    at_level = @course.extract_outcome_by_parent( @course.course_outcomes, @course_outcome.parent ) 
    next_position = 1
    next_position = at_level[-1].position + 1 if at_level.length > 0
    @course_outcome.position = next_position
    
    # find the program outcomes that map
    program_outcomes = load_program_outcomes( @course )
    
    CourseOutcome.transaction do 
      if @course_outcome.save
        read_program_outcome_mappings_from_params( @course_outcome, program_outcomes, params )
        @course_outcome.save

        set_highlight( "course_outcome_#{@course_outcome.id}" )
        flash[:notice] = 'New course outcome has been saved.'
        redirect_to :action => 'index', :course => @course
      else
        render :action => 'new', :course => @course
      end
    end
  end
  
  def reorder
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    # get the outcomes at this level
    @course_outcomes = @course.extract_outcome_by_parent( @course.course_outcomes, params[:id].to_i ) 
    @parent = params[:id]
    
    @parent_outcome = CourseOutcome.find(@parent) if @parent != -1 rescue @parent_outcome = nil  
  end
  
  def sort
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    # get the outcomes at this level
    @course_outcomes = @course.extract_outcome_by_parent( @course.course_outcomes, params[:id].to_i ) 
    CourseOutcome.transaction do
      @course_outcomes.each do |outcome|
        outcome.position = params['outcome-order'].index( outcome.id.to_s ) + 1
        outcome.save
      end
    end
    
    render :nothing => true
  end
  
  def delete_all
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    CourseOutcome.delete_all( ["course_id = ?", @course.id] )
    
    flash[:notice] = "All outcomes have been deleted."
    redirect_to :action => 'index', :course => @course
  end
  
  def destroy
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    @course_outcome = CourseOutcome.find(params[:id])
    children = @course_outcome.child_outcomes
    
    CourseOutcome.transaction do
      if children.length > 0
        parents_children = @course.extract_outcome_by_parent( @course.course_outcomes, @course_outcome.parent )
        position = parents_children.length + 1
        
        children.each do |child|
          child.parent = @course_outcome.parent
          child.position = position
          position = position.next
          child.save
        end       
      end
      
      @course_outcome.clear_program_outcome_mappings
      @course_outcome.destroy
    end
    
    
    redirect_to :action => 'index', :course => @course
  end
  
  def import_outcomes
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    @course_template = CourseTemplate.find(params[:import_from]) rescue @course_template = nil
    
    if @course_template.nil?
      flash[:badnotice] = "Course template could not be found."
      redirect_to :action => 'index', :course => @course
      return
    end
    
    success = false
    Course.transaction do
      # make sure that this course is mapped to the same programs as in the program template
      @course_template.programs.each do |program|
        add = true
        @course.programs.each do |course_program|
          if course_program.id == program.id
            add = false
          end
        end 
        @course.programs << program if add == true
      end
      @course.save
      
      # for each outcome in the template
      parent_map = Hash.new
      parent_map[-1] = -1
      # hard part - copy all the objectives
      @course_template.ordered_outcomes.each do |copy_outcome|
        new_outcome = CourseOutcome.new
        new_outcome.outcome = copy_outcome.outcome
        new_outcome.position = copy_outcome.position
        new_outcome.parent = parent_map[copy_outcome.parent]
        new_outcome.save
        
        copy_outcome.course_template_outcomes_program_outcomes.each do |copo|
          new_outcome.course_outcomes_program_outcomes << copo.clone_into_course( new_outcome.id )
        end
        new_outcome.save
        
        parent_map[copy_outcome.id] = new_outcome.id
        
        @course.course_outcomes << new_outcome
      end
      @course.save
      
      
      flash[:notice] = 'Course outcomes import from template succeeded.'
      success = true
    end
    
    flash[:badnotice] = "Outcomes import failed." unless success
    redirect_to :action => 'index', :course => @course
  end

  def export_outcomes
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    success = false
    CourseTemplate.transaction do
      @new_template = CourseTemplate.new
      @new_template.title = "EXPORT #{@course.title} - #{@course.short_description}"
      @new_template.start_date = "#{@course.term.semester}"
      @new_template.approved = false
      @new_template.save
      
      # map to programs
      @course.programs.each do |program|
        @new_template.programs << program
      end
      
      # create the outcomes
      # for each outcome in the template
      parent_map = Hash.new
      parent_map[-1] = -1
      # hard part - copy all the objectives
      @course.ordered_outcomes.each do |copy_outcome|
        new_outcome = CourseTemplateOutcome.new
        new_outcome.outcome = copy_outcome.outcome
        new_outcome.position = copy_outcome.position
        new_outcome.parent = parent_map[copy_outcome.parent]
        new_outcome.save
        
        copy_outcome.course_outcomes_program_outcomes.each do |copo|
          new_outcome.course_template_outcomes_program_outcomes << copo.clone_into_template(new_outcome.id)
        end
        new_outcome.save
        
        parent_map[copy_outcome.id] = new_outcome.id
        
        @new_template.course_template_outcomes << new_outcome
      end
      @new_template.save
      
      @course.programs.each do |program|
        message = "A new course template '#{@new_template.title}' has been exported by #{@user.display_name} and requires your approval."
        link = url_for :controller => '/program', :action => 'template', :id => program.id, :course => nil rescue link = nil      
        Notification.create( message, program.users, link )        
      end
      
      flash[:notice] = 'Course outcomes export to template succeeded.'
      success = true
    end
    
    flash[:badnotice] = "Outcomes export failed." unless success
    redirect_to :action => 'index', :course => @course
  end
  
  def assignments
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    @numbers = load_outcome_numbers( @course )
    set_title
    @title = "Assignment to outcomes report."
  end
  
  def course_program_report
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    
    @numbers = load_outcome_numbers( @course )
    
    @title = "'#{@course.title}' Outcomes to Program Outcomes Report"    
    respond_to do |format|
        format.html {
          @breadcrumb = Breadcrumb.for_course(@course, true)
          @breadcrumb.outcomes = true
          @breadcrumb.text = "Course / Program Outcomes"
        }
        format.csv  { 
          response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
          response.headers['Content-Disposition'] = "attachment; filename=#{@course.short_description}_course_outcomes.csv"
          render :layout => 'noright' 
        }
        
    end
  end

  
  def rubrics_report
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_edit_outcomes' )
    set_title
    
    RubricLevel.for_course( @course )

    build_course_rubrics_report()
    
    respond_to do |format|
        format.html {
          
        }
        format.csv  { 
          response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
          response.headers['Content-Disposition'] = "attachment; filename=#{@course.short_description}_course_outcomes_rubrics_report.csv"
          render :layout => 'noright' 
        }
        
    end
  end

private
  def set_title
    @title = "Course Outcomes - #{@course.title}"
    @breadcrumb = Breadcrumb.for_course(@course, true)
    @breadcrumb.outcomes = true
  end
  
  def read_program_outcome_mappings_from_params( course_outcome, program_outcomes, params )
    program_outcomes.each do |program_outcome|
      mapping_level = params["program_outcome_#{program_outcome.id}"]
      unless mapping_level.eql?('N')
        copo = CourseOutcomesProgramOutcome.new
        copo.course_outcome = course_outcome
        copo.program_outcome = program_outcome
        copo.level_some = mapping_level.eql?('S')
        copo.level_moderate = mapping_level.eql?('M')
        copo.level_extensive = mapping_level.eql?('E')
        course_outcome.course_outcomes_program_outcomes << copo
      end 
    end
  end
  
  def load_program_outcomes( course )
    program_outcomes = Array.new
    course.programs.each do |program|
      program.program_outcomes.each do |prog_outcome|
        program_outcomes << prog_outcome
      end
    end
    return program_outcomes
  end
  
end
