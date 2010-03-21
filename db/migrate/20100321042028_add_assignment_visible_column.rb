class AddAssignmentVisibleColumn < ActiveRecord::Migration
  def self.up
     add_column( :assignments, :visible, :boolean, :null => false, :default => true )
  end

  def self.down
    remove_column( :assignments, :visible )
  end
end
