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
