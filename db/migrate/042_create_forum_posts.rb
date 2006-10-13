class CreateForumPosts < ActiveRecord::Migration
  def self.up
    create_table :forum_posts do |t|
      t.column :headline, :string, :null => false
      t.column :post, :text, :null => false
      t.column :post_html, :text, :null => false
      t.column :forum_topic_id, :integer, :null => false
      
      t.column :parent_post, :integer, :null => false
      
      t.column :user_id, :integer, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
      
      t.column :replies, :integer, :null => true
      t.column :last_user_id, :integer, :null => true
      
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :forum_posts
  end
end
