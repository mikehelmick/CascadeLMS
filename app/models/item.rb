require 'MyString'

class Item < ActiveRecord::Base
  has_many :feeds, :through => :feeds_items
  has_many :item_shares, :dependent => :destroy

  has_many :item_comments, :order => 'created_at asc', :dependent => :destroy

  has_many :a_plus, :dependent => :destroy
  
  belongs_to :course
  belongs_to :user
  belongs_to :item
  
  belongs_to :assignment
  belongs_to :post
  belongs_to :document
  belongs_to :wiki
  belongs_to :forum_post
  
  before_save :transform_markup

  def title
    return "Assignment '#{assignment.title}'" if assignment?
    return "Graded Assignment '#{graded_assignment.title}'" if graded_assignment?
    return "Document '#{document.title}'" if document?
    return "Forum #{forum_post.headline}" if forum?
    return "Blog '#{post.title}'" if blog_post?
    return "Wiki Page '#{wiki.page}'" if wiki?
    ""
  end

  def mark_notifications_read_for_user(user)
    notes = Notification.find(:all, :conditions => ["user_id = ? and item_id = ? and acknowledged = ?", user.id, self.id, false])
    notes.each do |note|
      note.acknowledged = true
      note.save
    end
  end

  # Gets users that have done the APlus action on this post.
  # If a user is passed in, and the have done the aplus action, they should be in the list
  def aplus_users(user = nil, limit = 15)
    selected_user_plus = false
    aplus_users = Hash.new
    all_aplus = APlus.find(:all, :conditions => ["item_id = ?", self.id])
    all_aplus.each do |aplus|
      aplus_users[aplus.user_id] = aplus.user
      selected_user_plus = true if !user.nil? && user.id == aplus.user_id
    end

    return Array.new if aplus_users.size == 0

    rtnArray = Array.new
    sampleSize = limit
    if selected_user_plus
      rtnArray << user
      aplus_users[user.id] = nil
      sampleSize = sampleSize + 1
    end
    # Randomly fill in the rest of the array
    randomly_got_user = false;
    aplus_users.keys.sample(sampleSize).each do |key|
      if selected_user_plus && key == user.id
        randomly_got_user = true
      elsif rtnArray.size < limit
        rtnArray << aplus_users[key]
      end
    end
    return rtnArray
  end

  def assignment?
    return !self.assignment_id.nil? && self.assignment_id > 0
  end

  def graded_assignment?
    return !self.graded_assignment_id.nil? && self.graded_assignment_id > 0
  end

  def graded_assignment
    return Assignment.find(graded_assignment_id) if graded_assignment?
    return nil
  end

  def forum?
    return !self.forum_post_id.nil? && self.forum_post_id > 0
  end

  def document?
    return !self.document_id.nil? && self.document_id > 0
  end

  def blog_post?
    return !self.post_id.nil? && self.post_id > 0
  end

  def wiki?
    return !self.wiki_id.nil? && self.wiki_id > 0
  end

  def visible_to_user?(user)
    course_ids = Hash.new
    user.courses.each { |c| course_ids[c.id] = true }

    self.item_shares.each do |share|
      return true if !share.user_id.nil? && share.user_id == user.id
      return true if !share.course_id.nil? && course_ids[share.course_id]
    end

    return false
  end

  def self.add_comment(item, comment)
    noCacheItem = nil
    Item.transaction do
      uncached do
        noCacheItem = Item.find(item.id, :lock => true)
        noCacheItem.comment_count = noCacheItem.comment_count + 1
        
        comment.item = noCacheItem
        comment.save
        noCacheItem.save
      end
    end
    return noCacheItem
  end

  def build_message(item, notification)
    users = notification.get_recent_users()
    names = Array.new
    users.each do |u|
      names << u.display_name
    end

    common = "give an A+ to your post, #{item.title}"
    if names.size == 0
      return ""
    elsif names.size == 1
      return "#{names[0]} #{common}"
    elsif names.size == 2
      return "#{names[0]} and #{names[1]} #{common}"
    elsif names.size == 3
      return "#{names[0..-2].join(", ")} and #{names[-1]} #{common}"
    else
      other_count = item.aplus_count - names.size
      user_word = 'user'
      user_word = 'users' if other_count > 1
      return "#{names.join(", ")} and #{other_count} other #{user_word} #{common}"
    end
  end

  def notify_for_aplus(aplus_user, link)
    # If the item isn't owned, we can't add a notification for A+ actions.
    return if self.user.nil?
    
    Item.transaction do
      #uncached do
        # Re-find the item w/ a lock. This will block other update actions on the item.
        item = Item.find(self.id, :lock => true)
        # If found - this was an add. If not found, this was a removal of an A+
        # There are race conditions here, but since we're processing notificaitons for an item
        # in a lock, we should end up in the correct state.
        aplus = APlus.find(:first, :conditions => ["item_id = ? and user_id =?", item.id, aplus_user.id])

        # See if there is an existing notification - if there is, lock it.
        notification = Notification.find(:first, :conditions => ["user_id = ? and item_id = ? and aplus = ?", item.user_id, item.id, true], :lock => true)
        unless notification.nil?
          # Corner case - this was an aplus removal, and now we're at zero. Remove the notification
          if item.aplus_count == 0
            notification.destroy
            notification = nil
          else
            # Update the notification, make it unacknowledged, and bump the time.
            notification.add_to_recent_users(aplus_user)
            notification.acknowledged = false
            notification.emailed = false
          end
        else
          # Create a new notification, for the item owner from the aplus user.
          notification = Notification.create_aplus(item, item.user, aplus_user)
          notification.item_id = item.id
        end
      
        unless notification.nil?
          # The message building is common. The message associated with a notification will be updated
          # as the notification changes.
          notification.notification = build_message(item, notification)
          notification.link = link
          notification.save
        end
      #end
    end
  end

  # Toggle the A+ status for an item/user pair.
  # This is done in a transaction, using locking on the item.
  #
  # Returns a pair of:
  #   updated item (w/ new count), APlus record for user (or nil)
  def self.toggle_plus(item, user)
    nitem = nil
    aplus = nil
    
    Item.transaction do
      uncached do
        nitem = Item.find(item.id, :lock => true)
        aplus = APlus.find(:first, :conditions => ["item_id = ? and user_id =?", item.id, user.id], :lock => true)

        if aplus.nil?
          aplus = APlus.for(item, user)
          nitem.aplus_count = nitem.aplus_count + 1
        else
          APlus.delete_all(["item_id = ? and user_id =?", item.id, user.id])
          aplus = nil
          nitem.aplus_count = nitem.aplus_count - 1
          # sanity check condition
          nitem.aplus_count = 0 if nitem.aplus_count < 0
        end
        
        # Save everything back, commit
        nitem.save
      end
    end

    return nitem, aplus
  end

  # Share this item with a whole course.
  def share_with_course(course, timestamp)
    ItemShare.for_course(self, course)
    publish_to_course(course, timestamp)
  end
  
  # Share with a specific user only.
  def share_with_user(user, timestamp)
    ItemShare.for_user(self, user)
    publish_to_user(user, timestamp)
  end

  # Check if an individual user did an A+ operation
  def user_aplus?(user)
    return !APlus.find(:first, :conditions => ["item_id = ? and user_id =?", self.id, user.id]).nil?
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
    feed = course.create_feed
    FeedsItems.create(feed.id, self.id, timestamp)

    # publish to the subscribers
    feed.feed_subscriptions.each do |fs|
      publish_to_user(fs.user, timestamp)
    end
  end

  def publish_to_user(user, timestamp)
    # We need to put this item in the target user's feed
    user_feed_id = user.create_feed.id
    FeedsItems.create(user_feed_id, self.id, timestamp)
  end
end
