class CreateCourseOutcomesRubrics < ActiveRecord::Migration
  def self.up
    create_table :course_outcomes_rubrics do |t|
        t.column :rubric_id, :integer, :null => false
        t.column :course_outcome_id, :integer, :null => false

        t.timestamps
    end
    add_index(:course_outcomes_rubrics, [:rubric_id, :course_outcome_id], :unique => true)
  end

  def self.down
    drop_table :course_outcomes_rubrics
  end
end
