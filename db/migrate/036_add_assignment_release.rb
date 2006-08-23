class AddAssignmentRelease < ActiveRecord::Migration
  def self.up
    add_column( :assignments, :released, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :assignments, :released )
  end
end
