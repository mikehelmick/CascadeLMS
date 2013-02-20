require 'MyString'

class ForumPost < ActiveRecord::Base

  belongs_to :forum_topic
  belongs_to :user
  
  validates_presence_of :headline, :post
  
  before_save :transform_markup

  has_one :item, :dependent => :destroy
  
  def create_item()
    item = Item.new
    item.user_id = self.user_id
    item.course_id = self.forum_topic.course_id
    item.body = "#{self.user.display_name} created a new post in the forum '#{self.forum_topic.topic}'.\n #{self.post}"
    item.enable_comments = false
    item.enable_reshare = false
    item.forum_post_id = self.id
    item.created_at = self.created_at
    item.public = false
    return item
  end

  def publish()
    if parent_post == 0
      item = create_item()
      item.save
      item.share_with_course(self.forum_topic.course, self.created_at)
    end
  end

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
	  
	  temp_post = self.post
	  temp_post = temp_post.apply_code_tag
    temp_post = temp_post.apply_quote_tag
    
    self.post_html = HtmlEngine.apply_textile( temp_post )
  end
  
  protected :transform_markup
	

end

