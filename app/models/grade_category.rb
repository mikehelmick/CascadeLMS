class GradeCategory < ActiveRecord::Base
  
  
  def GradeCategory.for_course( course )
    GradeCategory.find(:all, :conditions => ["course_id = ? or course_id = ?", 0, course.id], :order => 'category asc')
  end
  
end
