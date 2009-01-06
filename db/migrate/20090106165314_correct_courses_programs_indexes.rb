class CorrectCoursesProgramsIndexes < ActiveRecord::Migration
  def self.up
    remove_column( :courses_programs, :id )
  end

  def self.down
    add_column( :courses_programs, :id, :integer, :null => false )
  end
end
