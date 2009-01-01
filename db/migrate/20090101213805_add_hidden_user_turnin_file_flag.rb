class AddHiddenUserTurninFileFlag < ActiveRecord::Migration
  def self.up
       add_column( :user_turnin_files, :hidden, :boolean, :null => false, :default => false )
    end

    def self.down
      remove_column( :user_turnin_files, :hidden )
  end
end
