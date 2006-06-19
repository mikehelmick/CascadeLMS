class JournalTask < ActiveRecord::Base
  
  def JournalTask.for_course( course )
    JournalTask.find(:all, :conditions => ["course_id = ? or course_id = ?", 0, course.id], :order => 'task asc')
  end
  
end
