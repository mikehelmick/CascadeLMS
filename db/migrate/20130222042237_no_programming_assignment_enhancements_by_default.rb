class NoProgrammingAssignmentEnhancementsByDefault < ActiveRecord::Migration
  def self.up
    change_column(:course_settings, :enable_prog_assignments, :boolean, :default => false)
  end

  def self.down
  end
end
