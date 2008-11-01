class AddCourseEmailSig < ActiveRecord::Migration
  def self.up
      add_column( :course_settings, :email_signature, :text, :null => false, :default => "" )
    end

    def self.down
      remove_column( :course_settings, :email_signature )
  end
end
