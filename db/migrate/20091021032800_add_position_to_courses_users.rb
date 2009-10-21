class AddPositionToCoursesUsers < ActiveRecord::Migration
  def self.up
     add_column( :courses_users, :position, :int, :null => false, :default => 1000 )
  end

  def self.down
    remove_column( :courses_users, :position )
  end
end
