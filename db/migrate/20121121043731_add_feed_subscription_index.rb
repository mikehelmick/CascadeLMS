class AddFeedSubscriptionIndex < ActiveRecord::Migration
  def self.up
    add_index(:feed_subscriptions, [:feed_id, :user_id], {:name => 'feed_user_idx', :unique => true})

    Setting.create :name => 'social_upgrade', :value => '0', :description => 'Has the social upgrade been run?'
  end

  def self.down
    remove_index(:feed_subscriptions, :name => 'feed_user_idx')
  end
end
