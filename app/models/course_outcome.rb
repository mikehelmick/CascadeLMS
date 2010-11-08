
class CourseOutcome < ActiveRecord::Base
  validates_presence_of :outcome
  
  belongs_to :course
  
  has_many :course_outcomes_program_outcomes
  has_many :program_outcomes, :through => :course_outcomes_program_outcomes
  
  has_and_belongs_to_many :rubrics
 
  def child_outcomes
    CourseOutcome.find(:all, :conditions => ["parent = ?",self.id], :order => "position ASC")
  end
  
  def clear_program_outcome_mappings
    CourseOutcomesProgramOutcome.delete_all( ["course_outcome_id = ?", self.id] )
  end
  
  def mapped_to_program_outcome?( prog_outcome_id )
    self.program_outcomes.each do |i|  
      return true if i.id == prog_outcome_id
    end
    return false
  end
  
  def get_depth_level( prog_outcome_id ) 
    self.course_outcomes_program_outcomes.each do |copo|
      if copo.program_outcome_id == prog_outcome_id 
        return "extensive" if copo.level_extensive
        return "moderate" if copo.level_moderate
        return "some" if copo.level_some
      end
    end
    
    return "none"
  end
  
  def get_depth_level_short( prog_outcome_id )
    depth_level = get_depth_level(prog_outcome_id)
    return 'E' if depth_level.eql?('extensive')
    return 'M' if depth_level.eql?('moderate')
    return 'S' if depth_level.eql?('some')
    return 'N'
  end
  
  
end
