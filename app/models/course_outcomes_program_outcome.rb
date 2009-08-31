class CourseOutcomesProgramOutcome < ActiveRecord::Base
  
  belongs_to :course_outcome
  belongs_to :program_outcome
  
  def clone_into_template( course_template_outcome_id ) 
    copo = CourseTemplateOutcomesProgramOutcome.new
    copo.course_template_outcome_id = course_template_outcome_id
    copo.program_outcome_id = self.program_outcome_id
    copo.level_some = self.level_some
    copo.level_moderate = self.level_moderate
    copo.level_extensive = self.level_extensive
    copo.save
    return copo
  end
  
end
