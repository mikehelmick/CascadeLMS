class AddRecentCommenters < ActiveRecord::Migration
  def self.up
    add_column(:items, :recent_commenters, :string, :null => false)
    add_column(:items, :unique_commenters, :int, :null => false, :default => 0)
  end

  def self.down
    remove_column(:items, :recent_commenters)
    remove_column(:items, :unique_commenters)
  end
end
