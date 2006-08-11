class GradeEntry < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :grade_item
  belongs_to :course
  
  validates_numericality_of :points
  
end
