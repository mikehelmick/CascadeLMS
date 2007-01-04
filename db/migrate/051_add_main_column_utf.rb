class AddMainColumnUtf < ActiveRecord::Migration
  def self.up
    add_column( :user_turnin_files, :main, :boolean, :null => false, :default => false )
    add_column( :user_turnin_files, :main_candidate, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :user_turnin_files, :main )
    remove_column( :user_turnin_files, :main_candidate )
  end
end
