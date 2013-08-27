class FeedsItems < ActiveRecord::Base
  belongs_to :feed
  belongs_to :item

  def self.create(feed_id, item_id, timestamp = Time.now)
    fi = FeedsItems.find(:first, :conditions => ["feed_id = ? and item_id = ?", feed_id, item_id])
    if fi.nil?
      fi = FeedsItems.new
      fi.feed_id = feed_id
      fi.item_id = item_id
      fi.timestamp = timestamp
      # If the item is already there, just succeed the create.
      fi.save rescue true
    end
    true
  end

  # Filter out items that this user can no longer see. This could be due
  # to remove from a course.
  def self.apply_acls(feeds_items, user)
    if user.nil?
      # If user is nil, then this is public access.
      feeds_items.select do |feeds_items| 
        if feeds_items.item.nil?
          false 
        else 
          feeds_items.item.public 
        end 
      end
    else
      # nil items should be removed, and items where the ACL check is false should be removed.  
      feeds_items.select { |feeds_items| !feeds_items.item.nil? && feeds_items.item.acl_check?(user) }
    end
  end

  def self.update_timestamp(item_id, timestamp)
    FeedsItems.update_all(["timestamp = #{timestamp.strftime("%Y-%m-%d %H:%M:%S")}"], "item_id = #{item_id}")
  end
end
