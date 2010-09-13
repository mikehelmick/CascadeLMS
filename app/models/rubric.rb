class Rubric < ActiveRecord::Base
  validates_presence_of :primary_trait, :no_credit_criteria, :part_credit_criteria, :full_credit_criteria
  validates_numericality_of :no_credit_points, :part_credit_points, :full_credit_points 
  
  belongs_to :assignment
  acts_as_list :scope => :assignment
  
  belongs_to :course
  
  has_and_belongs_to_many :course_outcomes
  
  has_many :rubric_entries, :dependent => :destroy
  
  before_save :normalize_points
  
  def self.process_full_mapping(params, course)
    errors = Array.new

    loaded_rubrics = Hash.new
    loaded_outcomes = Hash.new

    CourseOutcomesRubrics.transaction do
      params.keys.each do |key|
        if key[0..6].eql?('rubric_') && !key.index('_co_').nil?
          parts = key.split('_')
          
          rubric_id = parts[1].to_i
          coutcome_id = parts[3].to_i
          
          valid_mapping = true
          
          # Validate rubric
          if loaded_rubrics[rubric_id].nil?
            rubric = Rubric.find(rubric_id) rescue rubric = nil
            if (!rubric.nil? && rubric.course_id == course.id) 
              loaded_rubrics[rubric_id] = true
            else
              errors << "Rubric id #{rubric_id} is not in this course, invalid request."
              valid_mapping = false
            end
          end
          
          # Validate course outcome
          if loaded_outcomes[coutcome_id].nil?
            outcome = CourseOutcome.find(coutcome_id) rescue outcome = nil
            if (!outcome.nil? && outcome.course_id == course.id)
              loaded_outcomes[coutcome_id] = true
            else
              errors << "Course outcome id #{coutcome_id} is not in this course, invalid request."
              valid_mapping = false
            end
          end
          
          # Save mapping
          if valid_mapping
            newMapping = CourseOutcomesRubrics.new
            newMapping.rubric_id = rubric_id
            newMapping.course_outcome_id = coutcome_id
            newMapping.save
          end
        end
      end
    end
    
    return errors    
  end
  
  def mapped_to_course_outcome?( outcome_id )
    self.course_outcomes.each do |i|  
      return true if i.id == outcome_id
    end
    return false
  end
  
  def copy_to(assignment)
    newCopy = self.clone()
    newCopy.assignment_id = assignment.id
    newCopy.save
    
    # Copy the course outcome mappings
    self.course_outcomes.each do |co|
      newCopy.course_outcomes << co
    end
    newCopy.save
    
    return newCopy
  end
  
  def copy_to_course(course)
    newCopy = self.clone()
    newCopy.assignment_id = 0
    newCopy.course_id = course.id
    newCopy.save
    return newCopy
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
