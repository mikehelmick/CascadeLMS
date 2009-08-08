class Rubric < ActiveRecord::Base
  validates_presence_of :primary_trait, :no_credit_criteria, :part_credit_criteria, :full_credit_criteria
  validates_numericality_of :no_credit_points, :part_credit_points, :full_credit_points 
  
  belongs_to :assignment
  acts_as_list :scope => :assignment
  
  belongs_to :course
  
  has_and_belongs_to_many :course_outcomes
  
  has_many :rubric_entries, :dependent => :destroy
  
  before_save :normalize_points
  
  def mapped_to_course_outcome?( outcome_id )
    self.course_outcomes.each do |i|  
      return true if i.id == outcome_id
    end
    return false
  end
  
  def normalize_points
    # Normalize to 1 decimal point
    self.no_credit_points = normalize_point_value( self.no_credit_points )
    self.part_credit_points = normalize_point_value( self.part_credit_points )
    self.full_credit_points = normalize_point_value( self.full_credit_points )
    self.above_credit_points = normalize_point_value( self.above_credit_points )
  end
  
  def normalize_point_value( value )
    as_s = sprintf("%.2f", value)
    if as_s[-2..-1].eql?("00") 
      return value.to_i
    else
      return as_s.to_f
    end
  end
  
  
end
