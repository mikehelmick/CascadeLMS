class CreateCourseTemplateOutcome < ActiveRecord::Migration
  def self.up
    create_table :course_template_outcomes do |t|
      t.column :course_template_id, :integer
      t.column :outcome, :text, :null => false
      t.column :position, :integer
      
      t.column :parent, :integer, :null => false, :default => -1

      t.timestamps
    end
  end

  def self.down
    drop_table :course_template_outcomes
  end
end
