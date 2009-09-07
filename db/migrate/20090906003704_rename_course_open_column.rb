class RenameCourseOpenColumn < ActiveRecord::Migration
  def self.up
    rename_column(:courses, :open, :course_open)
  end

  def self.down
    rename_column(:courses, :course_open, :open)
  end
end
