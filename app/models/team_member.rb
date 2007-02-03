class TeamMember < ActiveRecord::Base
  
  belongs_to :project_team
  belongs_to :user
  belongs_to :course
  
end
