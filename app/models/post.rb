class Post < ActiveRecord::Base
  has_many :comments, :order => "created_at", :dependent => :destroy
  belongs_to :user
  belongs_to :course
  
  validates_presence_of :title, :body
  
  before_save :transform_markup
  
  def featured_text
    return "Yes" if self.featured
    return "No"
  end
  
  def published_text
    return "Yes" if self.published
    return "No"    
  end
  
  def number_of_comments
    Comment.count(:conditions => ["post_id = ?", self.id])
  end
    		
	def transform_markup
	  self.body_html = HtmlEngine.apply_textile( self.body )
  end
  
  protected :transform_markup
  
end
