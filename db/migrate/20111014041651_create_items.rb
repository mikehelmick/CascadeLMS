class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items do |t|
      # Author of the post. A course is an entity that can "co-author" a post
      t.column :user_id, :integer, :null => false
      t.column :course_id, :integer, :null => false
      
      # Text of the post
      t.column :body, :text, :null => false
      t.column :body_html, :text, :null => false

      # Access control
      t.column :enable_comments, :boolean, :null => false, :default => true
      t.column :enable_reshare, :boolean, :null => false, :default => true
      # If a post is public, we can put it here.
      t.column :public, :boolean, :null => false, :default => true

      # Links! Posts can be associated with many things in CascadeLMS
      t.column :course_id, :integer, :null => true
      t.column :assignment_id, :integer, :null => true
      t.column :graded_assignment_id, :integer, :null => true
      t.column :post_id, :integer, :null => true
      t.column :document_id, :integer, :null => true
      t.column :wiki_id, :integer, :null => true
      t.column :forum_post_id, :integer, :null => true
      
      # Timestamps.
      # updated_at will be used to pump posts
      t.timestamps
    end
    add_index(:items, [:user_id])
  end

  def self.down
    drop_table :items
  end
end
