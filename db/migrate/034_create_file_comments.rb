class CreateFileComments < ActiveRecord::Migration
  def self.up
    create_table :file_comments do |t|
      t.column :user_turnin_file_id, :integer, :null => false
      t.column :line_number, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :comments, :text
      # t.column :name, :string
    end
    
    add_index(:file_comments, [:user_turnin_file_id, :line_number], :name => 'file_comments_file_line_number_idx', :unique => true )
    add_index(:file_comments, [:user_turnin_file_id], :name => 'file_line_number_idx', :unique => false )
  end

  def self.down
    drop_table :file_comments
  end
end
