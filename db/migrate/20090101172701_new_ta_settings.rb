class NewTaSettings < ActiveRecord::Migration
  def self.up
    add_column( :course_settings, :ta_view_quiz_results, :boolean, :null => false, :default => false )
    add_column( :course_settings, :ta_view_survey_results, :boolean, :null => false, :default => false )
    add_column( :course_settings, :ta_view_already_graded_assignments, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :course_settings, :ta_view_quiz_results )
    remove_column( :course_settings, :ta_view_survey_results )
    remove_column( :course_settings, :ta_view_already_graded_assignments )
  end
end
