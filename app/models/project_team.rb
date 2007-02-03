class ProjectTeam < ActiveRecord::Base
  
  belongs_to :course
  
  validates_presence_of :team_id, :name
  
  has_many :team_members, :dependent => :destroy
  has_many :team_wiki_pages, :dependent => :destroy
  has_many :team_Emails, :dependent => :destroy
  
  def on_team?( user )
    team_members.each do |m|
      return true if m.user_id == user.id
    end
    return false
  end
  
end
