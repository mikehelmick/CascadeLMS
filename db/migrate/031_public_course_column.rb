class PublicCourseColumn < ActiveRecord::Migration
  def self.up
    add_column( :courses, :public, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :courses, :public )
  end
end
