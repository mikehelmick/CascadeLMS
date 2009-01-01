class AddAutoAddFlagToUserFiles < ActiveRecord::Migration
  def self.up
       add_column( :user_turnin_files, :auto_added, :boolean, :null => false, :default => false )
    end

    def self.down
      remove_column( :user_turnin_files, :auto_added )
  end
end
