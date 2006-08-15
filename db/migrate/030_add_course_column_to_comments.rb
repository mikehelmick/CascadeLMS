class AddCourseColumnToComments < ActiveRecord::Migration
  def self.up
    add_column( :comments, :course_id, :integer, :null => false )
  end

  def self.down
    remove_column( :comments, :course_id )
  end
end
