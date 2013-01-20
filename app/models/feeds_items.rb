class FeedsItems < ActiveRecord::Base
  belongs_to :feed
  belongs_to :item

  def self.create(feed_id, item_id, timestamp = Time.now)
    fi = FeedsItems.new
    fi.feed_id = feed_id
    fi.item_id = item_id
    fi.timestamp = timestamp
    fi.save
  end

  # Filter out items that this user can no longer see. This could be due
  # to remove from a course.
  def self.apply_acls(feeds_items, user)
    # nil items should be removed, and items where the ACL check is false should be removed.
    feeds_items.select { |feeds_items| !feeds_items.item.nil? && feeds_items.item.acl_check?(user) }
  end

  def self.update_timestamp(item_id, timestamp)
    FeedsItems.update_all(["timestamp = #{timestamp.strftime("%Y-%m-%d %H:%M:%S")}"], "item_id = #{item_id}")
  end
end
