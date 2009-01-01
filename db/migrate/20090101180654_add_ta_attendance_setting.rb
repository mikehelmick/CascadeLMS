class AddTaAttendanceSetting < ActiveRecord::Migration
  def self.up
    add_column( :course_settings, :ta_manage_attendance, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :course_settings, :ta_manage_attendance )
  end
end
