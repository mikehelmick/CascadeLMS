class CreateForumTopics < ActiveRecord::Migration
  def self.up
    create_table :forum_topics do |t|
      t.column :course_id, :integer, :null => false
      t.column :topic, :string, :null => false
      t.column :position, :integer, :null => false
      t.column :allow_posts, :boolean, :null => false, :default => true
      t.column :user_id, :integer, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
      t.column :post_count, :integer, :null => false
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :forum_topics
  end
end
