class AddCustomScoreForRubricEntries < ActiveRecord::Migration
  def self.up
    add_column( :rubric_entries, :custom_score, :boolean, :null => false, :default => false )
    add_column( :rubric_entries, :score, :float, :null => true )
  end

  def self.down
    remove_column( :rubric_entries, :score )
    remove_column( :rubric_entries, :custom_score )
  end
end
