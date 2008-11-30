class UsersAddProgramManagerFlag < ActiveRecord::Migration
  def self.up
    add_column( :users, :program_coordinator, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :users, :program_coordinator )
  end
end
