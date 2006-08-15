class Post < ActiveRecord::Base
  has_many :comments, :order => "created_at", :dependent => :destroy
  belongs_to :user
  belongs_to :course
  
  validates_presence_of :title, :body
  
  before_save :transform_markup
  
  def summary_date
    created_at.to_date.to_formatted_s(:short)
  end
  
  def acronym
    'Blog Post'
  end
  
  def icon
    'pencil'
  end
  
  def summary_action
    'posted by:'
  end
  
  def summary_actor
    self.user.display_name
  end
  
  def summary_title
    self.title
  end
  
  
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
