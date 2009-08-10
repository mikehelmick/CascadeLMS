class RubricLevel < ActiveRecord::Base
  
  validates_presence_of :l1_name
  validates_presence_of :l2_name
  validates_presence_of :l3_name
  validates_presence_of :l4_name
  
  def RubricLevel.for_course( course )
    rubric = RubricLevel.find(:first, :conditions => ["course_id = ?", course.id])
    if rubric.nil?
      copyFrom = RubricLevel.find(:first, :conditions => ["course_id = ?", 0])
      
      rubric = RubricLevel.new
      rubric.l1_name = copyFrom.l1_name
      rubric.l2_name = copyFrom.l2_name
      rubric.l3_name = copyFrom.l3_name
      rubric.l4_name = copyFrom.l4_name
      rubric.course_id = course.id
      rubric.save
      
    end
    return rubric
  end
  
end
