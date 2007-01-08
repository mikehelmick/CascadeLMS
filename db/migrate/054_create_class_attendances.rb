class CreateClassAttendances < ActiveRecord::Migration
  def self.up
    create_table :class_attendances do |t|
      t.column :class_period_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :course_id, :integer, :null => false
      t.column :correct_key, :boolean, :null => false, :default => true
      
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :class_attendances
  end
end
