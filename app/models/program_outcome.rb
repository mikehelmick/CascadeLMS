class ProgramOutcome < ActiveRecord::Base
  belongs_to :program
  acts_as_list :scope => :program
  
end
