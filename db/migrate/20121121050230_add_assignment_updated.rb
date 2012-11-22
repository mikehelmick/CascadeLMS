class AddAssignmentUpdated < ActiveRecord::Migration
  def self.up
    add_column(:assignments, :created_at, :datetime, :null => false)
    add_column(:assignments, :updated_at, :datetime, :null => false)
  end

  def self.down
    remove_column(:assignments, :created_at)
    remove_column(:assignments, :updated_at)
  end
end
