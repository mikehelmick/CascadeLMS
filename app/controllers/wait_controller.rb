class WaitController < ApplicationController

  before_filter :ensure_logged_in
  
  layout 'wait'
  
  def for_all
    @auto_refresh = true
    @queue = GradeQueue.find( :all, :conditions => ["assignment_id = ? and user_id = ? and batch = ?", params[:assignment], @user.id, params[:id] ] )
  
  
    all_done = true
    @queue.each { |item| all_done = false unless item.serviced || item.failed }
    if all_done 
      redirect_to :controller => 'instructor/turnins', :course => params[:course], :assignment => params[:assignment]
      flash[:notice] = 'Grading for this assignment has finished.'
      return
    end
  
  end

  def grade
    @auto_refresh = true
    @queue = GradeQueue.find( params[:id] ) 
    
    if @queue.failed
      redirect_to :action => 'failed', :id => params[:id]
      
    elsif @queue.serviced
      
      if @queue.user_id == @queue.user_turnin.user_id
        flash[:notice] = "Automatic grading of your assignment has completed."
        redirect_to :controller => '/turnins', :action => 'feedback', :course => @queue.assignment.course, :assignment => @queue.assignment
      else
        # assume that the instructor queued the assignment and redirect to the appropriate page
        flash[:notice] = "Automatic grading of this student's current turnin has completed, new results below."
        redirect_to :controller => 'instructor/turnins', :course => @queue.assignment.course, :assignment => @queue.assignment, :student => @queue.user_turnin.user_id, :action => 'view_io_tests'
      end
      
    elsif @queue.acknowledged
      flash[:notice] = "Your assignment is currently being graded by the server."
    
    else
      flash[:notice] = "Your assignment is in the queue to be graded, please wait."
      
    end
  end
  
  def failed
    @queue = GradeQueue.find( params[:id] ) 
    if ! @queue.failed
      redirect_to :action => 'grade', :id => params[:id]
    end
  end
  
  def retry
    @queue = GradeQueue.find( params[:id] ) 
    unless !@queue.failed
      if @queue.assignment.closed?
        flash[:notice] = "Your turn-in set was not reopened, the assignment is past due."
      else
        flash[:notice] = "Your turn-in set has been reopened, please finalize before the due date."
        @queue.user_turnin.sealed = false
        @queue.user_turnin.finalized = false
        @queue.user_turnin.save
      end
      
      redirect_to :controller => '/turnins', :course => @queue.assignment.course, :assignment => @queue.assignment
    else
      redirect_to :action => 'grade', :course => @queue.assignment.course, :assignment => @queue.assignment, :id => @queue.id
    end
    
  end

end
