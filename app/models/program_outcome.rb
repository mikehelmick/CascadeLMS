class ProgramOutcome < ActiveRecord::Base
  validates_presence_of :outcome
  
  belongs_to :program
  acts_as_list :scope => :program
  
  has_many :course_outcomes_program_outcomes
  has_many :course_outcomes, :through => :course_outcomes_program_outcomes
  
  def before_destroy
    ## need to delete course outcomes and course template outcome mappings
    CourseOutcomesProgramOutcome.delete_all( ["program_outcome_id = ?", self.id] )
    CourseTemplateOutcomesProgramOutcome.delete_all( ["program_outcome_id = ?", self.id] )
  end
  
end
