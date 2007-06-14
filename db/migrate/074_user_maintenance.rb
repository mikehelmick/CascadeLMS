class UserMaintenance < ActiveRecord::Migration
  def self.up
    add_column( :users, :activated, :boolean, :null => false, :default => false )
    add_column( :users, :activation_token, :string, :null => false, :default => '' )
    add_column( :users, :forgot_token, :string, :null => false, :default => '' )
  end

  def self.down
    remove_column( :users, :activated )
    remove_column( :users, :activation_token )
    remove_column( :users, :forgot_token )
  end
end
