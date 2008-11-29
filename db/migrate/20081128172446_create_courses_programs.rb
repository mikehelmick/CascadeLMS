class CreateCoursesPrograms < ActiveRecord::Migration
  def self.up
    create_table :courses_programs do |t|
        t.column :course_id, :integer, :null => false
        t.column :program_id, :integer, :null => false

        t.timestamps
      end
      add_index(:courses_programs, [:course_id, :program_id], :unique => true)
  end

  def self.down
    drop_table :courses_programs
  end
end
