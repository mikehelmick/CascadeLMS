class TeamWikiPage < ActiveRecord::Base
  
  validates_presence_of :page, :content
  
  belongs_to :project_team
  belongs_to :user
  
  before_save :transform_markup
  
  def TeamWikiPage.find_or_create( team, user, page_name )
    cur_page = TeamWikiPage.find(:first, :conditions => ["project_team_id = ? and page = ?", team.id, page_name ], :order => "revision DESC" ) rescue cur_page = nil
    
    if cur_page.nil?
      cur_page = TeamWikiPage.new
      cur_page.project_team = team
      cur_page.content = "This is a new Wiki page named '#{page_name}'."
      cur_page.user = user
      cur_page.revision = 1
      cur_page.page = page_name
      cur_page.save 
    end
    
    return cur_page
  end
  
  def transform_markup
	  self.content_html = HtmlEngine.apply_textile( self.content )
  end
  
  protected :transform_markup
  
end
