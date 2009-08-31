class AddOutcomeMapingLevels < ActiveRecord::Migration
  def self.up
    add_column( :course_outcomes_program_outcomes, :level_some, :boolean, :null => false, :default => false )
    add_column( :course_outcomes_program_outcomes, :level_moderate, :boolean, :null => false, :default => false )
    add_column( :course_outcomes_program_outcomes, :level_extensive, :boolean, :null => false, :default => true )
    
    add_column( :course_template_outcomes_program_outcomes, :level_some, :boolean, :null => false, :default => false )
    add_column( :course_template_outcomes_program_outcomes, :level_moderate, :boolean, :null => false, :default => false )
    add_column( :course_template_outcomes_program_outcomes, :level_extensive, :boolean, :null => false, :default => true )
    
  end

  def self.down
    remove_column( :course_outcomes_program_outcomes, :level_extensive )
    remove_column( :course_outcomes_program_outcomes, :level_moderate )
    remove_column( :course_outcomes_program_outcomes, :level_some )
    
    remove_column( :course_template_outcomes_program_outcomes, :level_extensive )
    remove_column( :course_template_outcomes_program_outcomes, :level_moderate )
    remove_column( :course_template_outcomes_program_outcomes, :level_some )
    
  end
end
