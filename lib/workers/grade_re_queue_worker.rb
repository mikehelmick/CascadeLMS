# Put your code that runs your task inside the do_work method it will be
# run automatically in a thread. You have access to all of your rails
# models.  You also get logger and results method inside of this class
# by default.
class GradeReQueueWorker < BackgrounDRb::Worker::RailsBase
  
  def do_work(args)
    # This method is called in it's own new thread when you
    # call new worker. args is set to :args
    
    time = Time.now - 5.minutes
    
    items = GradeQueue.find(:all, :conditions => ["acknowledged = ? and serviced = ? and updated_at < ?", true, false, time], :order => "updated_at asc" ) rescue item = nil


    items.each do |item|
        item.queued = false
        item.acknowledged = false
        item.serviced = false
        item.save
        logger.info("Requeue of item, id=#{item.id}, idle longer then 3 minutes")
    end
    
    if items.size
      logger.info("No idle items in the queue at #{Time.now.to_formatted_s(:rfc822)}.")
    end

    results[:do_work_time] = Time.now.to_s
    results[:done_with_do_work] = true
    delete
    
  end

end
GradeReQueueWorker.register
