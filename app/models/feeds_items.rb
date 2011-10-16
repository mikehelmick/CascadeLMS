class FeedsItems < ActiveRecord::Base
  belongs_to :feed
  belongs_to :item

  def self.create(feed_id, item_id)
    fi = FeedsItems.new
    fi.feed_id = feed_id
    fi.item_id = item_id
    fi.timestamp = Time.now
    fi.save
  end

  def self.update_timestamp(item_id, timestamp)
    FeedsItems.update_all(["timestamp = #{timestamp.strftime("%Y-%m-%d %H:%M:%S")}"], "item_id = #{item_id}")
  end
end
