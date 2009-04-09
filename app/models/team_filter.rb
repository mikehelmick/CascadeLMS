class TeamFilter < ActiveRecord::Base
  
  belongs_to :assignment
  belongs_to :project_team
  
end
