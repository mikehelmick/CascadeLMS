class CreateAutoGradeSettings < ActiveRecord::Migration
  def self.up
    create_table :auto_grade_settings, :id => false do |t|
      t.column :assignment_id, :int
      
      t.column :student_style, :boolean, :null => false, :default => true
      t.column :style, :boolean, :null => false, :default => true
      
      t.column :student_io_check, :boolean, :null => false, :default => false
      t.column :io_check, :boolean, :null => false, :default => false
      
      t.column :student_autograde, :boolean, :null => false, :default => false
      t.column :autograde, :boolean, :null => false, :default => false
      
      # t.column :name, :string
    end
    
    add_index(:auto_grade_settings, :assignment_id, :unique => true)
  end

  def self.down
    drop_table :auto_grade_settings
  end
end
