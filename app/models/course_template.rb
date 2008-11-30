class CourseTemplate < ActiveRecord::Base
  
  has_and_belongs_to_many :programs
  
  has_many :course_template_outcomes, :order => "position", :dependent => :destroy
  
  def mapped_to_program?( program_id )
    self.programs.each do |i|  
      return true if i.id == program_id
    end
    return false
  end
  
  def ordered_outcomes
    all_outcomes = self.course_template_outcomes
    
    ordered = add_outcomes_at_level( Array.new, all_outcomes, -1 )
      
    return ordered
  end
  
  def add_outcomes_at_level( rtnArr, outcomes, parent ) 
    #puts "ADD parent: #{parent} \n    -----> #{rtnArr.inspect}\n"
    
    this_level_outcomes = extract_outcome_by_parent( outcomes, parent ).sort { |a,b| a.position <=> b.position }
    #puts "THIS LEVEL: #{this_level_outcomes.inspect}\n"
    this_level_outcomes.each do |outcome|
      rtnArr << outcome
      rtnArr = add_outcomes_at_level( rtnArr, outcomes, outcome.id )
    end   
    
    rtnArr
  end
  
  def extract_outcome_by_parent( outcomes, parent ) 
    #puts "EXTRACT: parent: #{parent}\n"  
    rtnArr = Array.new
    outcomes.each do |outcome|
      rtnArr << outcome if outcome.parent == parent
    end
    return rtnArr
  end
  
end
