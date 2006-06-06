class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.column :course_id, :integer, :null => false
      t.column :position, :integer, :null => false
      t.column :title, :string, :null => false
      t.column :filename, :string, :null => false
      t.column :content_type, :string, :null => false
      t.column :comments, :text, :null => true
      t.column :comments_html, :text, :null => true
      t.column :created_at, :datetime, :null => false
      t.column :extension, :string
      t.column :size, :string
      t.column :published, :boolean, :null => false, :default => true
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :documents
  end
end
