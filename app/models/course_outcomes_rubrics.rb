class CourseOutcomesRubrics < ActiveRecord::Base

  belongs_to :rubric
  belongs_to :course_outcome

end
