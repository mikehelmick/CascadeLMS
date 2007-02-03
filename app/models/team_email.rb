class TeamEmail < ActiveRecord::Base
  
  validates_presence_of :message, :subject
  
  belongs_to :project_team
  belongs_to :user

end
