class GradeQueue < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :assignment
  belongs_to :user_turnin
  
end
