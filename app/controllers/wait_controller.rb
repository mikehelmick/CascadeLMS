class WaitController < ApplicationController

  before_filter :ensure_logged_in
  
  layout 'wait'

  def grade
    @queue = GradeQueue.find( params[:id] ) 
    
    if @queue.serviced
      flash[:notice] = "Automatic grading of your assignment has completed."
      redirect_to :controller => '/turnins', :action => 'feedback', :course => @queue.assignment.course, :assignment => @queue.assignment
    
    elsif @queue.acknowledged
      flash[:notice] = "Your assignment is currently being graded by the server."
    
    else
      flash[:notice] = "Your assignment is in the queue to be graded, please wait."
      
    end
  end

end
