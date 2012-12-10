class AddItemToNotification < ActiveRecord::Migration
  def self.up
    add_column(:notifications, :item_id, :integer, :null => true)
    add_column(:notifications, :aplus, :boolean, :null => false, :default => false)
    add_column(:notifications, :comment, :boolean, :null => false, :default => false)
    
    add_index(:notifications, [:item_id], :unique => false)
  end

  def self.down
    remove_column(:notifications, :item_id)
    remove_Column(:notifications, :aplus)
    remove_Column(:notifications, :comment)
  end
end
