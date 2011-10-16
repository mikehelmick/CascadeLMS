class Item < ActiveRecord::Base
  has_many :feeds, :through => :feeds_items
  has_many :item_shares, :dependent => :destroy

  # Share this item with a whole course.
  def share_with_course(course)
    ItemShare.for_course(self, course)
    publish_to_course(course)
  end
  
  # Share with a specific user only.
  def share_with_user(user)
    ItemShare.for_user(self, user)
    publish_to_user(user)
  end

  private
  def publish_to_course(course)
    # publish to the course's feed
    course_feed_id = course.create_feed.id
    FeedsItems.create(course_feed_id, self.id)

    # publish to the the feed for all users in the course
    courses_users = course.non_dropped_users
    courses_users.each { |u| publish_to_user(courses_users.user) }
  end

  def publish_to_user(user)
    # We need to put this item in the target user's feed
    user_feed_id = user.create_feed.id
    FeedsItems.create(user_feed_id, self.id)
  end

end
