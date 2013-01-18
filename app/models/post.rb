class Post < ActiveRecord::Base
  has_many :comments, :order => "created_at", :dependent => :destroy
  belongs_to :user
  belongs_to :course

  #has_one :item, :dependent => :destroy
  
  validates_presence_of :title, :body
  
  before_save :transform_markup

  def publish
    transaction do
      save
      if self.visible?
        item = create_item()
        item.save
        item.share_with_course(self.course, self.created_at)
      end
    end
  end

  def visible?
    return self.published && self.created_at <= Time.now
  end

  def add_comment(comment)
    item = nil
    transaction do
      save
      comment.post = self
      comment.save
      item = Item.find(:first, :conditions => ["post_id = ?", self.id], :lock => true)
      item.comment_count = item.comment_count + 1
      item.save
    end
    return item
  end

  def remove_comment(comment)
    transaction do
      item = Item.find(:first, :conditions => ["post_id = ?", self.id], :lock => true)
      item.comment_count = item.comment_count - 1
      item.comment_count = 0 if item.comment_count < 0
      item.save
      comment.destroy
    end
  end
  
  def clone_to_course( course_id, user_id, time_offset = nil? )
    dup = Post.new
    dup.course_id = course_id
    dup.user_id = user_id
    dup.featured = self.featured
    dup.title = self.title
    dup.body = self.body
    dup.body_html = self.body_html
    dup.enable_comments = self.enable_comments
    if time_offset.nil?
      dup.created_at = Time.at( self.created_at + time_offset )
    else 
      dup.created_at = self.created_at
    end
    dup.published = self.published
    return dup
  end
  
  def summary_date
    created_at.to_date.to_formatted_s(:short)
  end
  
  def feed_action
    'Blog Post'
  end
  
  def acronym
    'Blog Post'
  end
  
  def icon
    'icon-pencil'
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

  def create_item()
    item = Item.new
    item.user_id = self.user_id
    item.course_id = self.course.id
    item.body = self.body
    item.enable_comments = true
    item.enable_reshare = false
    item.post_id = self.id
    return item
  end

  protected
    		
	def transform_markup
	  this_post = self.body
	  this_post = this_post.apply_code_tag
	  this_post = this_post.apply_quote_tag
	  
	  self.body_html = HtmlEngine.apply_textile(this_post)
  end
end
