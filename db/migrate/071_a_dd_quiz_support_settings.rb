class ADdQuizSupportSettings < ActiveRecord::Migration
  def self.up
    add_column( :course_settings, :enable_quizzes, :boolean, :null => false, :default => true )
    add_column( :course_settings, :ta_create_quizzes, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :course_settings, :enable_quizzes )
    remove_column( :course_settings, :ta_create_quizzes )
  end
end
