class CreateUserProfiles < ActiveRecord::Migration
  def self.up
    create_table :user_profiles, :id => false  do |t|
      t.column :user_id, :integer

      t.column :major, :string, :null => true
      t.column :year, :string, :null => true
      t.column :about_me, :string, :null => true

      t.timestamps
    end
    add_index(:user_profiles, [:user_id], :unique => true)
  end

  def self.down
    drop_table :user_profiles
  end
end
