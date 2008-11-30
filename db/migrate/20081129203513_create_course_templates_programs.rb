class CreateCourseTemplatesPrograms < ActiveRecord::Migration
  def self.up
    create_table( :course_templates_programs, :id => false, :primary_key => 'course_template_id, program_id') do |t|
      t.column :course_template_id, :integer, :null => false
      t.column :program_id, :integer, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :course_templates_programs
  end
end
