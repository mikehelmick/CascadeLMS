class CreateWikis < ActiveRecord::Migration
  def self.up
    create_table :wikis do |t|
      t.column :course_id, :integer, :null => false
      t.column :page, :string, :null => false

      t.column :content, :text, :null => false
      t.column :content_html, :text, :null => false

      t.column :created_at, :timestamp, :null => false
      t.column :updated_at, :timestamp, :null => false
      t.column :user_id, :integer, :null => false

      t.column :revision, :integer, :null => false, :default => 1
          
      t.column :user_editable, :boolean, :null => false, :default => true
    end

    add_index(:wikis, [:course_id,:page,:revision], :unique => true)
  end

  def self.down
    drop_table :wikis
  end
end
