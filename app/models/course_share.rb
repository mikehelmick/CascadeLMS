class CourseShare < ActiveRecord::Base
  
  belongs_to :course
  belongs_to :user
  
  def reset
    self.assignments = false
    self.documents = false
    self.blogs = false
    self.outcomes = false
    self.rubrics = false
  end
  
  def CourseShare.full_share
    full = CourseShare.new
    full.assignments = true
    full.documents = true
    full.blogs = true
    full.outcomes = true
    full.rubrics = true
    return full
  end
  
end
