# Put your code that runs your task inside the do_work method it will be
# run automatically in a thread. You have access to all of your rails
# models.  You also get logger and results method inside of this class
# by default.
class AutoGradeMonitorWorker < BackgrounDRb::Worker::RailsBase
  
  def do_work(args)
    # This method is called in it's own new thread when you
    # call new worker. args is set to :args
    
    ## Free the in_service count
    to_free = GradeQueue.find(:all, :conditions => ["serviced = ? and (acknowledged = ? or queued = ? )", false, true, true] )
    to_free.each do |item|
      item.acknowledged = false;
      item.queued = false;
    end
    
    while( true )
    
      item = GradeQueue.find(:all, :conditions => ["acknowledged = ? and serviced = ? and queued = ?", false, false, false], :order => "created_at asc" ) rescue item = Array.new
      item = Array.new if item.nil?

      in_service = GradeQueue.count(:all, :conditions => ["serviced = ? and (acknowledged = ? or queued = ? )", false, true, true] ) rescue in_service = 0

      if item.size > 0 && in_service < 2

        schedule_me = item[0]

        schedule_me.queued = true
        schedule_me.message = "<p><b>You are next to be graded.</b></p>"
        schedule_me.save

        logger.info("Monitor found item to be scheduled, id=#{schedule_me.id}")

        MiddleMan.schedule_worker(
          :class => :auto_grade_worker,
          :args => schedule_me.id,
          :trigger_args => {
                :start => Time.now + 3.seconds
              }
        )

        logger.info("scheduled grade request #{schedule_me.id} ")

        count = 0
        item.each do |this_req| 
          if count > 0
            this_req.message = "<p>There are #{item.size - 1} assignemtns waiting to be graded.<br/>Your position in line is <b>#{count}</b></p>"
            this_req.save
          end
          count = count.next
        end

      elsif item.size > 0 && in_service >= 2
        ## update the queue positions
        count = 1
        item.each do |i| 
          i.message = "<p>There are #{item.size} assignemtns waiting to be graded.<br/>Your position in line is <b>#{count}</b></p>"
          i.save
          count = count.next
        end

      else
        logger.info("no grade requests at #{Time.now.to_formatted_s(:rfc822)}.")
      end
    
      sleep(10)
    end 
    
    results[:do_work_time] = Time.now.to_s
    results[:done_with_do_work] = true
    delete
  end

end
AutoGradeMonitorWorker.register
