class CoursesUser < ActiveRecord::Base
  belongs_to :course
  belongs_to :user
  
  belongs_to :crn
  
  def any_user?
    self.course_student || self.course_instructor || self.course_assistant || self.course_guest
  end
  
  def to_s
    user.to_s
  end
  
end
