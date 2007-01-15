class AddGradableColumnUtf < ActiveRecord::Migration
  def self.up
    add_column( :user_turnin_files, :gradable, :boolean, :null => false, :default => false )
    add_column( :user_turnin_files, :gradable_message, :text, :null => true )
    add_column( :user_turnin_files, :gradable_override, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :user_turnin_files, :gradable )
    remove_column( :user_turnin_files, :gradable_message )
    remove_column( :user_turnin_files, :gradable_override )
  end
end
