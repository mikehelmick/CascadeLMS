class CourseSettingsProjectTeams < ActiveRecord::Migration
  def self.up
     add_column( :course_settings, :enable_project_teams, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :course_settings, :enable_project_teams )
  end
end
