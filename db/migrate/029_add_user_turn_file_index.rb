class AddUserTurnFileIndex < ActiveRecord::Migration
  def self.up
     add_index(:user_turnin_files, [:user_turnin_id, :filename, :directory_parent], :name => 'unique_filename_idx', :unique => true)
  end

  def self.down
    remove_index :user_turnin_files, :name => :unique_filename_idx
  end
end
