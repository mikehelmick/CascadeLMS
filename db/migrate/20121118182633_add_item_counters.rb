class AddItemCounters < ActiveRecord::Migration
  def self.up
    add_column(:items, :comment_count, :integer, :null => false, :default => 0)
    add_column(:items, :aplus_count, :integer, :null => false, :default => 0)
  end

  def self.down
    remove_column(:items, :comment_count)
    remove_column(:items, :aplus_count)
  end
end
