class Notification < ActiveRecord::Base
  # What defines the number of recent users for a notification.
  NUM_RECENT_USERS = 3
  
  belongs_to :user
  has_one :item
  
  def Notification.create( text, users, link = nil )
    users.each do |user|
      notification = Notification.new
      notification.notification = text
      notification.user = user
      notification.link = link
      notification.emailed = false
      notification.acknowledged = false
      notification.save
    end
  end

  def Notification.create_proposal(user, text, link, course)
    notification = Notification.new
    notification.notification = text
    notification.user = user
    notification.link = link
    notification.emailed = false
    notification.acknowledged = false
    notification.course_id = course.id
    notification.proposal = true
    notification.save
  end

  # The notification text and link need to be filled in by the caller.
  def Notification.create_aplus(item, user, aplus_user)
    notification = Notification.new
    notification.user = user
    notification.emailed = false
    notification.acknowledged = false
    notification.aplus = true
    notification.add_to_recent_users(aplus_user)
    notification.item = item
    return notification
  end

  def Notification.create_comment(item, user)
    notification = Notification.new
    notification.user = user
    notification.emailed = false
    notification.acknowledged = false
    notification.comment = true
    notification.item = item
    return notification
  end

  def Notification.create_followed(user, text, link, following_user)
    notification = Notification.new
    notification.user = user
    notification.notification = text
    notification.link = link
    notification.emailed = false
    notification.acknowledged = false
    notification.followed_by_user_id = following_user.id
    return notification
  end

  def Notification.mark_following_notification_read(user, followed_by_user)
    notifications = Notification.find(:all, :conditions => ["user_id = ? and acknowledged = ? && followed_by_user_id = ?", user.id, false, followed_by_user.id])
    notifications.each do |note|
      note.acknowledged = true
      note.save
    end
    return notifications.size > 0
  end

  # Recent users is a list of 3 most recent actors on a notification that would have caused an update.
  # Some other count must be used to derive the "and X others" text that will go in the notification.
  def get_recent_users()
    return Array.new if self.recent_users.nil?
    recent = Array.new
    self.recent_users.split(',').each do |id|
      begin
        recent << User.find(id)
      rescue
        # If user was deleted, that's fine. Rely on cleanup job to patch up data.
      end
    end
    return recent
  end

  def add_to_recent_users(user)
    newRecentArray = Array.new
    if self.recent_users.nil?
      newRecentArray << user.id
    else
      newRecentArray = self.recent_users.split(',')
      if newRecentArray.index(user.id).nil?
        # not in the array, add it
        newRecentArray = newRecentArray.reverse.push(user.id).reverse[0, NUM_RECENT_USERS]
      end
    end
    self.recent_users = newRecentArray.join(',')
  end
end
