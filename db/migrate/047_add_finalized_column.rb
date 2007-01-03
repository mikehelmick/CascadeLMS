class AddFinalizedColumn < ActiveRecord::Migration
  def self.up
    add_column( :user_turnins, :finalized, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :user_turnins, :finalized )
  end
end
