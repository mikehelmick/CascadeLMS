class CreateCourseTemplates < ActiveRecord::Migration
  def self.up
    create_table :course_templates do |t|
      t.column :title, :string, :null => false
      t.column :start_date, :string, :null => true

      t.timestamps
    end
  end

  def self.down
    drop_table :course_templates
  end
end
