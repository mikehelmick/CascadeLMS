class RubricEntry < ActiveRecord::Base
  
  belongs_to :assignment
  belongs_to :user
  belongs_to :rubric
  
end
