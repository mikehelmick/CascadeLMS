class MakeDefaultFeedSubscriptionSilent < ActiveRecord::Migration
  def self.up
    change_column_default(:feed_subscriptions, :send_email, false)
  end

  def self.down
    change_column_default(:feed_subscriptions, :send_email, false)
  end
end
