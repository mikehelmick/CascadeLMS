class CreateCourseOutcomesRubrics < ActiveRecord::Migration
  def self.up
    create_table( :course_outcomes_rubrics, :id => false, :primary_key => 'course_outcome_id, rubric_id') do |t|
        t.column :course_outcome_id, :integer, :null => false
        t.column :rubric_id, :integer, :null => false

        t.timestamps
    end
    add_index(:course_outcomes_rubrics, 
              [:course_outcome_id, :rubric_id], 
              :unique => true,
              :name => "course_outcomes_rubrics_unique")
  end

  def self.down
    drop_table :course_outcomes_rubrics
  end
end
