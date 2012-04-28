class Item < ActiveRecord::Base
  has_many :feeds, :through => :feeds_items
  has_many :item_shares, :dependent => :destroy
  
  belongs_to :course
  belongs_to :user
  
  belongs_to :assignment
  belongs_to :post
  belongs_to :document
  belongs_to :wiki
  belongs_to :forum_post
  
  before_save :transform_markup

  # Share this item with a whole course.
  def share_with_course(course, timestamp = Time.now)
    ItemShare.for_course(self, course)
    publish_to_course(course, timestamp)
  end
  
  # Share with a specific user only.
  def share_with_user(user, timestamp = Time.now)
    ItemShare.for_user(self, user)
    publish_to_user(user, timestamp)
  end
  
  def transform_markup
	  this_post = self.body
	  this_post = this_post.apply_code_tag
	  this_post = this_post.apply_quote_tag
	  
	  self.body_html = HtmlEngine.apply_textile(this_post)
  end
  
  protected :transform_markup

  private
  def publish_to_course(course, timestamp)
    # publish to the course's feed
    course_feed_id = course.create_feed.id
    FeedsItems.create(course_feed_id, self.id, timestamp)

    # publish to the the feed for all users in the course
    courses_users = course.non_dropped_users
    courses_users.each do |u|
      publish_to_user(u, timestamp)
    end
  end

  def publish_to_user(user, timestamp)
    # We need to put this item in the target user's feed
    user_feed_id = user.create_feed.id
    FeedsItems.create(user_feed_id, self.id, timestamp)
  end

end
