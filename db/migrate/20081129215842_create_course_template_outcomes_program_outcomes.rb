class CreateCourseTemplateOutcomesProgramOutcomes < ActiveRecord::Migration
  def self.up
    create_table( :course_template_outcomes_program_outcomes, :id => false, :primary_key => 'course_template_outcome_id, program_outcome_id') do |t|
      t.column :course_template_outcome_id, :integer, :null => false
      t.column :program_outcome_id, :integer, :null => false
    
      t.timestamps
    end
    add_index(:course_template_outcomes_program_outcomes, 
              [:course_template_outcome_id, :program_outcome_id], 
              :unique => true,
              :name => "course_template_outcomes_program_outcomes_unique")
  end

  def self.down
    drop_table :course_template_outcomes_program_outcomes
  end
end
