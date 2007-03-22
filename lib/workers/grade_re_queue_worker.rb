# Put your code that runs your task inside the do_work method it will be
# run automatically in a thread. You have access to all of your rails
# models.  You also get logger and results method inside of this class
# by default.
class GradeReQueueWorker < BackgrounDRb::Worker::RailsBase
  
  def do_work(args)
    # This method is called in it's own new thread when you
    # call new worker. args is set to :args
    
    while( true )
    
      time = Time.now - 3.minutes

      items = GradeQueue.find(:all, :conditions => ["acknowledged = ? and serviced = ? and updated_at < ?", true, false, time], :order => "updated_at asc" ) rescue items = Array.new

      items.each do |item|
          item.queued = false
          item.acknowledged = false
          item.serviced = false
          item.message = "There appears to have been an error while evaluating this assignment.  Grading will restart shortly."
          item.save
          logger.info("Requeue of item, id=#{item.id}, idle longer then 5 minutes")
      end


      results[:do_work_time] = Time.now.to_s
      results[:done_with_do_work] = true
      delete
    
      sleep(60)
    end
    
  end

end
GradeReQueueWorker.register
