class AddAssignmentUpdated < ActiveRecord::Migration
  def self.up
    add_column(:assignments, :created_at, :datetime, :null => false, :default => 0)
    add_column(:assignments, :updated_at, :datetime, :null => false, :default => 0)
  end

  def self.down
    remove_column(:assignments, :created_at)
    remove_column(:assignments, :updated_at)
  end
end
