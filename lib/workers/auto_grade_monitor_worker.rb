require 'auto_grade_worker'

# Worker that moniters the AutoGrade queue
class AutoGradeMonitorWorker < BackgrounDRb::MetaWorker
  
  set_worker_name :auto_grade_monitor_worker
  
  
  def create(args = nil)
      logger.debug("Initialied auto_grade_monitor_worker")
      add_periodic_timer(15) { check_queue }
  end

  def free_in_service( args )
    ## Free the in_service count
    to_free = GradeQueue.find(:all, :conditions => ["serviced = ? and (acknowledged = ? or queued = ? )", false, true, true] )
    to_free.each do |item|
      item.acknowledged = false;
      item.queued = false;
      item.save
    end
    
  end
  
  def check_queue( args = nil )
    # This method is called in it's own new thread when you
    # call new worker. args is set to :args
    
    item = GradeQueue.find(:all, :conditions => ["acknowledged = ? and serviced = ? and queued = ?", false, false, false], :order => "created_at asc" ) rescue item = Array.new
    item = Array.new if item.nil?

    in_service = GradeQueue.count(:all, :conditions => ["serviced = ? and (acknowledged = ? or queued = ? )", false, true, true] ) rescue in_service = 0

      if item.size > 0 && in_service < 3

        schedule_me = item[0]

        schedule_me.queued = true
        schedule_me.message = "<p><b>You are next to be graded.</b></p>"
        schedule_me.save

        logger.info("Monitor found item to be scheduled, id=#{schedule_me.id}")

        MiddleMan.worker(:auto_grade_worker).async_execute(:arg => schedule_me.id,
                                                           :job_key => "ag#{schedule_me.id}")

        logger.info("scheduled grade request #{schedule_me.id} ")

        count = 0
        item.each do |this_req| 
          if count > 0
            extra = ''
            if Time.now - this_req.created_at > 120
              extra = "<br/><b>You have been waiting for over two minutes - if your place in line has not improved, please close this window and come back later today to check your submission status.</b>"
            end
            
            this_req.message = "<p>There are #{item.size - 1} assignments waiting to be graded.<br/>Your position in line is <b>#{count}</b>#{extra}</p>"
            this_req.save
          end
          count = count.next
        end

      elsif item.size > 0 && in_service >= 3
        ## update the queue positions
        count = 1
        item.each do |i| 
          i.message = "<p>There are #{item.size} assignments waiting to be graded.<br/>Your position in line is <b>#{count}</b></p>"
          i.save
          count = count.next
        end

      else
        logger.info("no grade requests at #{Time.now.to_formatted_s(:rfc822)}.")
      end
    
    #end 
    
  end

end
