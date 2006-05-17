class Term < ActiveRecord::Base
  validates_presence_of :term, :semester, :year, :current, :open
  
end
