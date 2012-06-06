class JournalsController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    create_breadcrumb()
    
    redirect_to :controller => 'assignments', :action => 'view', :course => @course.id, :id => @assignment.id, :assignment => nil
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }

  def new
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless course_open( @course, :controller => '/assignments', :action => 'view', :assignment => params[:assignment], :course => params[:course] )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_has_journals( @assignment )
    create_breadcrumb()
    
    @journal = Journal.new
    @journal.interruption_time = 0
    @journal.completed = false
    
    @journal_tasks = JournalTask.for_course( @course )
    @journal_stop_reasons = JournalStopReason.for_course( @course )
  end

  def create
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless course_open( @course, :controller => '/assignments', :action => 'view', :assignment => params[:assignment], :course => params[:course] )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_has_journals( @assignment )
    return unless assignment_open( @assignment, true )
    
    @journal = Journal.new(params[:journal])
    @journal.assignment = @assignment
    @journal.user = @user
    
    # create task xrefs
    @journal_tasks = JournalTask.for_course( @course )
    @journal_tasks.each { |x| @journal.journal_tasks << x unless params["task_id_#{x.id}"].nil? }
    
    # create stop reason xrefs
    @journal_stop_reasons = JournalStopReason.for_course( @course )
    @journal_stop_reasons.each { |x| @journal.journal_stop_reasons << x unless params["stop_reason_id_#{x.id}"].nil? }
    
    if @journal.save
      flash[:notice] = 'Journal entry was successfully created.'
      redirect_to :controller => '/assignments', :action => 'view', :course => @course, :assignment => nil, :id => @assignment.id
    else
      render :action => 'new'
    end
  end

  def edit
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless course_open( @course, :controller => '/assignments', :action => 'view', :assignment => params[:assignment], :course => params[:course] )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_has_journals( @assignment )
    return unless assignment_open( @assignment, true )
    create_breadcrumb()
    
    @journal = Journal.find(params[:id]) 
    
    @journal_tasks = JournalTask.for_course( @course )
    @journal_stop_reasons = JournalStopReason.for_course( @course )
  end

  def update
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless course_open( @course, :controller => '/assignments', :action => 'view', :assignment => params[:assignment], :course => params[:course] )
    
    @assignment = Assignment.find(params[:assignment]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_has_journals( @assignment )
    return unless assignment_open( @assignment, true )
    
    @journal = Journal.find(params[:id])
    @journal.journal_tasks.clear
    @journal.journal_stop_reasons.clear
    
    # create task xrefs
    @journal_tasks = JournalTask.for_course( @course )
    @journal_tasks.each { |x| @journal.journal_tasks << x unless params["task_id_#{x.id}"].nil? }
    
    # create stop reason xrefs
    @journal_stop_reasons = JournalStopReason.for_course( @course )
    @journal_stop_reasons.each { |x| @journal.journal_stop_reasons << x unless params["stop_reason_id_#{x.id}"].nil? }
    
    if @journal.update_attributes(params[:journal])
      flash[:notice] = 'Journal entry was successfully updated.'
      redirect_to :controller => '/assignments', :action => 'view', :course => @course, :assignment => nil, :id => @assignment.id
    else
      render :action => 'edit'
    end
  end
  
private
  def set_tab()
    @show_course_tabs = true
    @tab = "course_assignments"
    @title = "Assignment Journals"
  end

  def create_breadcrumb()
    @breadcrumb = Breadcrumb.for_course(@course)
    @breadcrumb.assignment = @assignment
    @breadcrumb.text = "Journal Entry"
  end
  
  def assignment_open( assignment, redirect = true  ) 
    unless assignment.close_date > Time.now
      flash[:badnotice] = "The requisted assignment is closed, no more files or information may be submitted."
      redirect_to :controller => '/assignments', :action => 'view', :course => @course, :id => assignment.id, :assignment => nil if redirect
      return false
    end
    true    
  end
  
end
