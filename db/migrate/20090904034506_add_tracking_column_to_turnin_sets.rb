class AddTrackingColumnToTurninSets < ActiveRecord::Migration
  def self.up
    add_column( :user_turnins, :force_update, :boolean, :null => false, :default => true )
  end

  def self.down
    remove_column( :user_turnins, :force_update )
  end
end
