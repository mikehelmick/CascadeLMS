class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.column :user_id, :integer, :null => false
      t.column :notification, :text, :null => false
      t.column :link, :text
      t.column :emailed, :boolean, :null => false, :default => false
      t.column :acknowledged, :boolean, :null => false, :default => false
      t.column :view_count, :integer, :null => false, :default => 0

      t.timestamps
    end
    
    add_index(:notifications, [:user_id], :unique => false)
    add_index(:notifications, [:user_id, :emailed], :unique => false)
  end

  def self.down
    drop_table :notifications
  end
end
