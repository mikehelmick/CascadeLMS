class CreateCoursesCrns < ActiveRecord::Migration
  def self.up
    create_table( :courses_crns, :id => false, :primary_key => 'course_id, crn_id' ) do |t|
      t.column :course_id, :integer, :null => false
      t.column :crn_id, :integer, :null => false
      # t.column :name, :string
    end
    add_index(:courses_crns, [:course_id, :crn_id], :unique => true)
  end

  def self.down
    drop_table :courses_crns
  end
end
