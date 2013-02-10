class AddUserIndexes < ActiveRecord::Migration
  def self.up
    # Increase username limit from 15 to 100 characters.
    change_column(:users, :uniqueid, :string, :limit => 100)

    add_index(:users, :uniqueid, :unique => true)
    add_index(:users, :email, :unique => true)
  end

  def self.down
    remove_index(:users, :uniqueid)
    remove_index(:users, :email)
  end
end
