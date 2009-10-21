class AddPositionToGradeItems < ActiveRecord::Migration
  def self.up
     add_column( :grade_items, :position, :int, :null => false, :default => 1000 )
  end

  def self.down
    remove_column( :grade_items, :position )
  end
end
