class AutoGradeHelper
  
  
  def AutoGradeHelper.schedule( assignment, user, current_turnin, app, flash )
    
    if assignment.auto_grade && !assignment.auto_grade_setting.nil?
      queue = GradeQueue.new
      queue.user = user
      queue.assignment = assignment
      queue.user_turnin = current_turnin
      if queue.save
        
        begin
          MiddleMan.schedule_worker(
            :class => :auto_grade_worker,
            :args => queue.id,
            :trigger_args => {
                  :start => Time.now + 1.seconds
                }
          )
        rescue
          flash[:badnotice] = "The AutoGrade server wasn't running - but I've started it up and your grading will be begin shortl (may take up to 60 seconds)."
          ## bounce the server - the stop and then the start (stop has no effect if not running)
          `#{app['ruby']} #{RAILS_ROOT}/script/backgroundrb stop`
          `#{app['ruby']} #{RAILS_ROOT}/script/backgroundrb start`
        end
        
        return queue
      else
        flash[:badnotice] = "There was an error scheduling your turn-in set for automatic evaluation, pleae inform your instructor or try again."    
      end
      
    end
    return nil
  end
  
  
end