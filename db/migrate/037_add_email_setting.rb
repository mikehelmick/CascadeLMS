class AddEmailSetting < ActiveRecord::Migration
  def self.up
    add_column( :course_settings, :ta_send_email, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :course_settings, :ta_send_email )
  end
end
