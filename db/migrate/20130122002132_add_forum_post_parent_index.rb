class AddForumPostParentIndex < ActiveRecord::Migration
  def self.up
    add_index(:forum_posts, [:parent_post], :unique => false, :name => 'forum_posts_parent_post_index')
  end

  def self.down
    remove_index :forum_posts, :name => :forum_posts_parent_post_index
  end
end
