class AddDropColumnToCoursesUsers < ActiveRecord::Migration
  def self.up
     add_column( :courses_users, :dropped, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :courses_users, :dropped )
  end
end
