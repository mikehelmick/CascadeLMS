class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.column :course_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :featured, :boolean, :null => false, :default => false
      t.column :title, :string, :null => false
      t.column :body, :text, :null => false
      t.column :body_html, :text, :null => false
      t.column :enable_comments, :boolean, :null => false, :default => true
      t.column :created_at, :datetime, :null => false
      t.column :published, :boolean, :null => false, :default => true
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :posts
  end
end
