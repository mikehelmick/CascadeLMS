class AddGitToCourseSettings < ActiveRecord::Migration
  def self.up
    add_column(:course_settings, :enable_github, :boolean, :null => false, :default => false)
    add_column(:course_settings, :github_server_id, :int, :null => true)
  end

  def self.down
    remove_column(:course_settings, :enable_git)
    remove_column(:course_settings, :github_server_id)
  end
end
