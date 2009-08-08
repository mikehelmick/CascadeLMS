class AutoGradeHelper
  
  def AutoGradeHelper.schedule_job( queueId )
    queue = GradeQueue.find(queueId)
    tag = "#{queue.assignment.course.id},#{queue.assignment.id},#{queue.user_turnin.user.id},#{queue.user_turnin.id}"
    Bj.submit "./script/runner ./jobs/autograde_job.rb #{queueId}", :tag => tag
  end
  
  def AutoGradeHelper.schedule( assignment, user, current_turnin, app, flash = nil )
    
    if assignment.auto_grade && !assignment.auto_grade_setting.nil?
      queue = GradeQueue.new
      queue.user = user
      queue.assignment = assignment
      queue.user_turnin = current_turnin
      if queue.save
        AutoGradeHelper.schedule_job( queue.id )
        
      else
        flash[:badnotice] = "There was an error scheduling your turn-in set for automatic evaluation, pleae inform your instructor or try again." unless flash.nil?
      end
      
    end
    return nil
  end
  
  
end