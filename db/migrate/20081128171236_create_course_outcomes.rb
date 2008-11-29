class CreateCourseOutcomes < ActiveRecord::Migration
  def self.up
    create_table :course_outcomes do |t|
      t.column :course_id, :integer
      t.column :outcome, :text, :null => false
      t.column :position, :integer
      
      t.column :parent, :integer, :null => false, :default => -1

      t.timestamps
    end
  end

  def self.down
    drop_table :course_outcomes
  end
end
