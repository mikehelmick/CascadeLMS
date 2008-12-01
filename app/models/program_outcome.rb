class ProgramOutcome < ActiveRecord::Base
  validates_presence_of :outcome
  
  belongs_to :program
  acts_as_list :scope => :program
  
  has_and_belongs_to_many :course_outcomes
  
end
