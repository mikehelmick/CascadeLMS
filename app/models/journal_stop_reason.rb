class JournalStopReason < ActiveRecord::Base
  
  def JournalStopReason.for_course( course )
    JournalStopReason.find(:all, :conditions => ["course_id = ? or course_id = ?", 0, course.id], :order => 'reason asc')
  end
  
end
