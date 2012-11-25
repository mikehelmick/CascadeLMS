class CreateItemComments < ActiveRecord::Migration
  def self.up
    create_table :item_comments do |t|
      t.column :item_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :body, :text, :null => false
      t.column :body_html, :text, :null => false
      t.column :edited, :boolean, :null => false, :default => false
      t.column :ip, :string, :null => false, :limit => 15
      
      t.timestamps
    end
  end

  def self.down
    drop_table :item_comments
  end
end
