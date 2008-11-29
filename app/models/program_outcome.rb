class ProgramOutcome < ActiveRecord::Base
  belongs_to :program
  acts_as_list :scope => :program
  
  has_and_belongs_to_many :course_outcomes
  
end
