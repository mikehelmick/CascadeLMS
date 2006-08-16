class AddCommentsColumnForGradeEntries < ActiveRecord::Migration
  def self.up
    add_column( :grade_entries, :comment, :string, :null => true )
  end

  def self.down
    remove_column( :grade_entries, :comment )
  end
end
