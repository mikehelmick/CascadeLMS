class AddTeamSettings < ActiveRecord::Migration
  def self.up
    add_column( :course_settings, :team_enable_wiki, :boolean, :null => false, :default => true )
    add_column( :course_settings, :team_enable_email, :boolean, :null => false, :default => true )
    add_column( :course_settings, :team_enable_documents, :boolean, :null => false, :default => true )
    add_column( :course_settings, :team_documents_instructor_upload_only, :boolean, :null => false, :default => false )
    add_column( :course_settings, :team_show_members, :boolean, :null => false, :default => true )
  end

  def self.down
    remove_column( :course_settings, :team_enable_wiki )
    remove_column( :course_settings, :team_enable_email )
    remove_column( :course_settings, :team_enable_documents )
    remove_column( :course_settings, :team_documents_instructor_upload_only )
    remove_column( :course_settings, :team_show_members )
  end
end
