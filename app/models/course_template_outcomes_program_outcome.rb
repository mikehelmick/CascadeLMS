class CourseTemplateOutcomesProgramOutcome < ActiveRecord::Base
  
  belongs_to :course_template_outcome
  belongs_to :program_outcome
  
  def clone_into_course( course_outcome_id ) 
    copo = CourseOutcomesProgramOutcome.new
    copo.course_outcome_id = course_outcome_id
    copo.program_outcome_id = self.program_outcome_id
    copo.level_some = self.level_some
    copo.level_moderate = self.level_moderate
    copo.level_extensive = self.level_extensive
    copo.save
    return copo
  end
  
end
