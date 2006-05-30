class CreateCourseInformations < ActiveRecord::Migration
  def self.up
    create_table :course_informations, :id => false do |t|
      t.column :course_id, :integer
      
      t.column :meeting_days, :string, :null => true
      t.column :meeting_time, :string, :null => true
      t.column :office_hours, :string, :null => true
      t.column :room, :string, :null => true
      
      # t.column :name, :string
    end
    add_index(:course_informations, [:course_id], :unique => true)
  end

  def self.down
    drop_table :course_informations
  end
end
