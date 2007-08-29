class AddCourseIdToGradeQueues < ActiveRecord::Migration
  def self.up
    add_column( :grade_queues, :course_id, :integer, :null => false, :default => -1 )
  end

  def self.down
    remove_column( :grade_queues, :course_id )
  end
end
