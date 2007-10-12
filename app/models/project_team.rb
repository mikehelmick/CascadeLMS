class ProjectTeam < ActiveRecord::Base
  
  belongs_to :course
  
  validates_presence_of :team_id, :name
  
  has_many :team_members, :dependent => :destroy
  has_many :team_wiki_pages, :dependent => :destroy
  has_many :team_emails, :dependent => :destroy
  has_many :team_documents, :dependent => :destroy
  
  def on_team?( user )
    team_members.each do |m|
      return true if m.user_id == user.id
    end
    return false
  end
  
  def team_member_names
    names = Array.new
    
    self.team_members.each do |user|
      names << user.display_name
    end    
    
    names.join(', ')
  end
  
end
