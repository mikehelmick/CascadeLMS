class AddCourseToQuizzes < ActiveRecord::Migration
  def self.up
    add_column( :quizzes, :course_id, :integer )
    change_column( :quizzes, :course_id, :integer, :null => false )
    add_index(:quizzes, [:course_id], :unique => false)
  end

  def self.down
    remove_column( :quizzes, :course_id )
  end
end
