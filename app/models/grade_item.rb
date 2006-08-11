class GradeItem < ActiveRecord::Base
  
  belongs_to :course
  belongs_to :grade_category
  
end
