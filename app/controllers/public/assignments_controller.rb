class Public::AssignmentsController < ApplicationController

  before_filter :set_tab
  before_filter :load_user_if_logged_in

  def index
    return unless load_course( params[:course] )
    return unless course_is_public( @course )

    # Request assignments for an invalid user - this may hide some assignments from the public.
    # Specifically assignments that 
    @assignments = @course.assignments_for_user( 0 )
    
    @current_assignments = Array.new
    @upcoming_assignments = Array.new
    @complete_assignments = Array.new

    @assignments.each do |a|
      if a.current?
        @current_assignments << a
      elsif a.upcoming?
        @upcoming_assignments << a
      else
        @complete_assignments << a
      end
    end
    
    RubricLevel.for_course(@course)

    set_title
    @public = true
    get_breadcrumb().text = 'Assignments'
  end

  def view
    return unless load_course( params[:course] )
    return unless course_is_public( @course )

    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    RubricLevel.for_course(@course)
    @numbers = load_outcome_numbers(@course) if @assignment.rubrics.size > 0 

    @now = Time.now
    set_title
    get_breadcrumb().assignment = @assignment
  end

  def download
    return unless load_course( params[:course] )
    return unless course_is_public( @course )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    @document = AssignmentDocument.find(params[:document]) rescue @document = AssignmentDocument.new
    return unless document_in_assignment( @document, @assignment )
       
    begin  
      send_file @document.resolve_file_name(@app['external_dir']), :filename => @document.filename, :type => "#{@document.content_type}", :disposition => 'inline'  
    rescue
      flash[:badnotice] = "Sorry - the requested document has been deleted or is corrupt."
      redirect_to :action => 'view', :assignment => @assignment, :course => @course
    end 
  end
  
  
  
  # private methods
private
  def assignment_available( assignment, redirect = true )
    unless assignment.open_date <= Time.now
      flash[:badnotice] = "The requisted assignment is not yet available."
      redirect_to :action => 'index' if redirect
      return false
    end
    true
  end
  
  def assignment_open( assignment, redirect = true  ) 
    unless assignment.close_date > Time.now
      flash[:badnotice] = "The requisted assignment is closed, no more files or information may be submitted."
      redirect_to :action => 'index' if redirect
      return false
    end
    true    
  end

  
  def document_in_assignment( document, assignment )
    unless document.assignment_id == assignment.id 
      flash[:badnotice] = "The requested document could not be found."
      redirect_to :action => 'view', :assignment => assignment, :course => @course
      return false
    end
    true
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_assignments"
    @title = "Course Assignments"
  end

  def set_title
    @title = "#{@course.title} (Course Assignments)"
    @title = "#{@assignment.title} - #{@course.title}" unless @assignment.nil?
  end

  def get_breadcrumb
    @breadcrumb = Breadcrumb.for_course(@course)
    @breadcrumb.public_access = true
    return @breadcrumb
  end  
end
