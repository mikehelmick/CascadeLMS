class CreateFileStyles < ActiveRecord::Migration
  def self.up
    create_table :file_styles do |t|
      t.column :user_turnin_file_id, :integer, :null => false
      t.column :begin_line, :integer
      t.column :begin_column, :integer
      t.column :end_line, :integer
      t.column :end_column, :integer
      t.column :package, :string
      t.column :class_name, :string
      t.column :message, :text
      
      t.column :style_check_id, :integer
      
      t.column :suppressed, :boolean, :null => false, :default => false
      # t.column :name, :string
    end
    
    add_index(:file_styles, [:user_turnin_file_id], :name => 'file_line_num_idx', :unique => false )
  end

  def self.down
    drop_table :file_styles
  end
end
