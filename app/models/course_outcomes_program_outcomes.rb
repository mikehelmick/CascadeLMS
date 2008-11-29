class CourseOutcomesProgramOutcomes < ActiveRecord::Base
  
  belongs_to :course_outcome
  belongs_to :program_outcome
  
end
