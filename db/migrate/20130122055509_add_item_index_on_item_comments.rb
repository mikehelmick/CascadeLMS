class AddItemIndexOnItemComments < ActiveRecord::Migration
  def self.up
    add_index(:item_comments, [:item_id], :unique => false, :name => 'item_comments_item_id_index')
  end

  def self.down
    remove_index :item_comments, :name => :item_comments_item_id_index
  end
end
