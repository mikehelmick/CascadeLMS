# Put your code that runs your task inside the do_work method it will be
# run automatically in a thread. You have access to all of your rails
# models.  You also get logger and results method inside of this class
# by default.
class GradeReQueueWorker < BackgrounDRb::MetaWorker
  
  set_worker_name :grade_re_queue_worker
  
  def create(args = nil)
    # This method is called in it's own new thread when you
    # call new worker. args is set to :args
    threshold = 60 # number of minutes to wait for a requeue
    
    #while( true )
    
      time = Time.now - threshold.minutes

      items = GradeQueue.find(:all, :conditions => ["acknowledged = ? and serviced = ? and updated_at < ?", true, false, time], :order => "updated_at asc" ) rescue items = Array.new

      items.each do |item|
          item.queued = false
          item.acknowledged = false
          item.serviced = false
          item.message = "There appears to have been an error while evaluating this assignment.  Grading will restart shortly."
          item.save
          logger.info("Requeue of item, id=#{item.id}, idle longer then #{threshold} minutes")
      end
    
      #sleep(60 * 60)
    #end
    
  end

end