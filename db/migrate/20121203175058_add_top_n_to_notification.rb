class AddTopNToNotification < ActiveRecord::Migration
  def self.up
    add_column(:notifications, :recent_users, :string, :null => true)
  end

  def self.down
    remove_column(:notifications, :recent_users)
  end
end
