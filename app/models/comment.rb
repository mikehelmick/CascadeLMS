class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  
  validates_presence_of :user_id, :body, :ip
  
  before_save :transform_markup
  
  def transform_markup
	  self.body_html = HtmlEngine.apply_textile( self.body )
  end
  
  protected :transform_markup
  
end
