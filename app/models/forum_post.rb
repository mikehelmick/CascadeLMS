class ForumPost < ActiveRecord::Base

  belongs_to :forum_topic
  belongs_to :user
  
  validates_presence_of :headline, :post
  
  before_save :transform_markup

  def last_user
    if ! self.last_user_id.nil?
      User.find( self.last_user_id ) 
    else
      return nil;
    end
  end

  def hot?
    !self.replies.nil? && self.replies > 20 
  end
  
  def medium?
    !hot? && !self.replies.nil? && self.replies > 10 
  end
  
  def transform_markup
	  self.post_html = HtmlEngine.apply_textile( self.post )
  end
  
  protected :transform_markup
	

end

