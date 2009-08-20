class Public::AssignmentsController < ApplicationController
  
  layout 'public'
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless course_is_public( @course )
  
    @assignments = @course.assignments_for_user( 0 )
  
    set_title
  end
  
  def view
    return unless load_course( params[:course] )
    return unless course_is_public( @course )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_available( @assignment )
    
    @now = Time.now
    set_title
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
  
  
end
