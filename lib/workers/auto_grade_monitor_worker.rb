# Put your code that runs your task inside the do_work method it will be
# run automatically in a thread. You have access to all of your rails
# models.  You also get logger and results method inside of this class
# by default.
class AutoGradeMonitorWorker < BackgrounDRb::Worker::RailsBase
  
  def do_work(args)
    # This method is called in it's own new thread when you
    # call new worker. args is set to :args
    
    item = GradeQueue.find(:first, :conditions => ["acknowledged = ? and serviced = ? and queued = ?", false, false, false], :order => "created_at asc" ) rescue item = nil
    
    
    unless item.nil?
      item.queued = true
      item.save
      logger.info("Monitor found item to be scheduled, id=#{item.id}")
      
      MiddleMan.schedule_worker(
        :class => :auto_grade_worker,
        :args => item.id,
        :trigger_args => {
              :start => Time.now + 3.seconds
            }
      )
        
      logger.info("Monitor scheduled queue item #{item.id} to run at #{Time.now.to_formatted_s(:rfc822)}.")
    else
      logger.info("No unacknowledged items in the queue at #{Time.now.to_formatted_s(:rfc822)}.")
    end
    
    results[:do_work_time] = Time.now.to_s
    results[:done_with_do_work] = true
    delete
  end

end
AutoGradeMonitorWorker.register
