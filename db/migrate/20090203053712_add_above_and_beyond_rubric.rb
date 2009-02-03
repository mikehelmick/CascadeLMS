class AddAboveAndBeyondRubric < ActiveRecord::Migration
  def self.up
    add_column( :rubrics, :above_credit_criteria, :text, :null => true, :default => nil )
    add_column( :rubrics, :above_credit_points, :integer, :null => false, :default => 0 )    
    add_column( :rubric_entries, :above_credit, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :rubrics, :above_credit_criteria )
    remove_column( :rubrics, :above_credit_points )
    remove_column( :rubric_entries, :above_credit )
  end
end
