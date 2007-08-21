class Wiki < ActiveRecord::Base
  
  validates_presence_of :page, :content
  
  belongs_to :course
  belongs_to :user
  
  before_save :transform_markup
  
  def Wiki.find_or_create( course, user, page_name )
    cur_page = Wiki.find(:first, :conditions => ["course_id = ? and page = ?", course.id, page_name ], :order => "revision DESC" ) rescue cur_page = nil
    
    if cur_page.nil?
      cur_page = Wiki.new
      cur_page.course = course
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
