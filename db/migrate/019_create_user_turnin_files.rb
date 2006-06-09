class CreateUserTurninFiles < ActiveRecord::Migration
  def self.up
    create_table :user_turnin_files do |t|
      t.column :user_turnin_id, :integer
      
      t.column :directory_entry, :boolean, :null => false, :defualt => false
      t.column :directory_parent, :integer, :null =>false
      
      t.column :position, :integer, :null => false
      t.column :filename, :string, :null => false
      t.column :content_type, :string, :null => false
      t.column :comments, :text, :null => true
      t.column :created_at, :datetime, :null => false
      t.column :extension, :string
      t.column :size, :string
    end
  end

  def self.down
    drop_table :user_turnin_files
  end
end
