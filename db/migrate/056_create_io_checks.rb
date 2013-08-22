class CreateIoChecks < ActiveRecord::Migration
  def self.up
    create_table :io_checks do |t|
      
      t.column :name, :string, :null => false
      t.column :description, :text, :null => true
      
      t.column :assignment_id, :integer, :null => false
      
      t.column :input, :text, :null => false
      t.column :output, :text, :null => false
      t.column :tolerance, :float, :null => false, :default => 1.0
      t.column :ignore_newlines, :boolean, :null => false, :default => false
      
      t.column :show_input, :boolean, :null => false, :default => false
      t.column :student_level, :boolean, :null => false, :default => false
    end
    
    add_index(:io_checks, [:name, :assignment_id], :name => 'io_checks_name_by_assignment', :unique => true )
    add_index(:io_checks, [:assignment_id], :unique => false)
  end

  def self.down
    drop_table :io_checks
  end
end
