class AddFirstPublishToFeedSubscriptions < ActiveRecord::Migration
  def self.up
    add_column(:feed_subscriptions, :caught_up, :boolean, :null => false, :default => false)
  end

  def self.down
    remove_column(:feed_subscriptions, :caught_up)
  end
end
