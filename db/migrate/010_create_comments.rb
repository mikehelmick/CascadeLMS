class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.column :post_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :body, :text, :null => false
      t.column :body_html, :text, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :ip, :string, :null => false, :limit => 15
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :comments
  end
end
