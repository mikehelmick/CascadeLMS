class CourseTemplateOutcomesProgramOutcomes < ActiveRecord::Base
  
  belongs_to :course_template_outcome
  belongs_to :program_outcome
  
end
