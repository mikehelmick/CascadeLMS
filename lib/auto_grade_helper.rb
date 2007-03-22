class AutoGradeHelper
  
  
  def AutoGradeHelper.schedule( assignment, user, current_turnin, app, flash )
    
    if assignment.auto_grade && !assignment.auto_grade_setting.nil?
      queue = GradeQueue.new
      queue.user = user
      queue.assignment = assignment
      queue.user_turnin = current_turnin
      if queue.save
          # we used to actively schedule here, but we don't want to do that anymore
        return queue
      else
        flash[:badnotice] = "There was an error scheduling your turn-in set for automatic evaluation, pleae inform your instructor or try again."    
      end
      
    end
    return nil
  end
  
  
end