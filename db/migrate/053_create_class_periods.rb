class CreateClassPeriods < ActiveRecord::Migration
  def self.up
    create_table :class_periods do |t|
      t.column :course_id, :integer, :null => false
      
      t.column :open, :boolean, :null => false, :default => true
      t.column :key, :string, :null => false
      
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
      
      t.column :position, :integer
      
      # t.column :name, :string
    end
    
    add_column( :course_settings, :enable_attendance, :boolean, :null => false, :default => false )
  end

  def self.down
    drop_table :class_periods
    
    remove_column( :course_settings, :enable_attendance )
  end
end
