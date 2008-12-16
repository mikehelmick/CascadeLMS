class Rubric < ActiveRecord::Base
  validates_presence_of :primary_trait, :no_credit_criteria, :part_credit_criteria, :full_credit_criteria
  validates_numericality_of :no_credit_points, :part_credit_points, :full_credit_points 
  
  belongs_to :assignment
  acts_as_list :scope => :assignment
  
  belongs_to :course
  
  has_and_belongs_to_many :course_outcomes
  
  def mapped_to_course_outcome?( outcome_id )
    self.course_outcomes.each do |i|  
      return true if i.id == outcome_id
    end
    return false
  end
  
  
end
