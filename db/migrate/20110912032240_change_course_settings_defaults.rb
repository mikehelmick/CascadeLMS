class ChangeCourseSettingsDefaults < ActiveRecord::Migration
  def self.up
    change_column(:course_settings, :enable_outcomes, :boolean, :default => true)
    change_column(:course_settings, :enable_project_teams, :boolean, :default => true)
  end

  def self.down
    change_column(:course_settings, :enable_outcomes, :boolean, :default => false)
    change_column(:course_settings, :enable_project_teams, :boolean, :default => false)
  end
end
