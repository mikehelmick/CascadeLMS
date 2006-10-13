class AddCourseSettingsForum < ActiveRecord::Migration
  def self.up
    add_column( :course_settings, :enable_forum, :boolean, :null => false, :default => true )
    add_column( :course_settings, :enable_forum_topic_create, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :course_settings, :enable_forum )
    remove_column( :course_settings, :enable_forum_topic_create )
  end
end
