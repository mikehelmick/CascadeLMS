class AddCrnIdToCoursesUsers < ActiveRecord::Migration
  def self.up
     add_column( :courses_users, :crn_id, :int, :null => true, :default => 0 )
  end

  def self.down
    remove_column( :courses_users, :crn_id )
  end
end
