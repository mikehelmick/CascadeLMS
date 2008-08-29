class Instructor::AssignmentIoChecksController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index 
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :controller => '/instructor/index', :action => 'index', :course => @course )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )
    return unless assignment_uses_io_autograde( @course, @assignment )

    @io_checks = IoCheck.find(:all, :conditions => ["assignment_id = ?", @assignment.id], :order => "name asc" ) 
   
    set_title
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }

  def new
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :controller => '/instructor/index', :action => 'index', :course => @course )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )
    return unless assignment_uses_io_autograde( @course, @assignment )
    
    @io_check = IoCheck.new
    
    set_title
  end

  def create
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :controller => '/instructor/index', :action => 'index', :course => @course )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )
    return unless assignment_uses_io_autograde( @course, @assignment )
    
    @io_check = IoCheck.new(params[:io_check])
    
    @io_check.assignment = @assignment
    
    if @io_check.save
      flash[:notice] = 'New I/O test was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :controller => '/instructor/index', :action => 'index', :course => @course )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )
    return unless assignment_uses_io_autograde( @course, @assignment )
    
    @io_check = IoCheck.find(params[:id])
    return unless io_check_for_assignment( @course, @assignment, @io_check)
    
    
  end

  def update
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :controller => '/instructor/index', :action => 'index', :course => @course )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )
    return unless assignment_uses_io_autograde( @course, @assignment )
    
    @io_check = IoCheck.find(params[:id])
    return unless io_check_for_assignment( @course, @assignment, @io_check)
    
    if @io_check.update_attributes(params[:io_check])
      flash[:notice] = 'I/O test was successfully updated.'
      flash[:highlight] = "check_#{@io_check.id}"
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  
  end

  def destroy
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless course_open( @course, :controller => '/instructor/index', :action => 'index', :course => @course )
    @assignment = Assignment.find( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_uses_autograde( @course, @assignment )
    return unless assignment_uses_io_autograde( @course, @assignment )
    
    IoCheck.find(params[:id]).destroy
    
    redirect_to :action => 'index'
  end
  
  
  private
  
  def io_check_for_assignment( course, assignment, io_check )
    unless io_check.assignment_id == assignment.id
      redirect_to :action => 'index', :course => course, :assignment => assignment
      flash[:notice] = "The requested I/O Test does not exist or is not part of the current assignment."
      return false
    end
    return true
    
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "I/O AutoGrade Settings - Assignment '#{@assignment.title}' - #{@course.title}"
  end
end
