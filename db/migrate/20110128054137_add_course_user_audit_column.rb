class AddCourseUserAuditColumn < ActiveRecord::Migration
  def self.up
     add_column( :courses_users, :audit_opt_in, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :courses_users, :audit_opt_in )
  end
end
