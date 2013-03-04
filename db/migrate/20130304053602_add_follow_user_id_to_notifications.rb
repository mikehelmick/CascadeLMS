class AddFollowUserIdToNotifications < ActiveRecord::Migration
  def self.up
    add_column(:notifications, :followed_by_user_id, :integer, :null => true)
  end

  def self.down
    remove_column(:notifications, :followed_by_user_id)
  end
end
