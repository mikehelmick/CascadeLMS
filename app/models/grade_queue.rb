class GradeQueue < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :assignment
  belongs_to :user_turnin
  belongs_to :course
  
  def before_save
    self.course = self.assignment.course unless self.assignment.nil?
  end
  
end
