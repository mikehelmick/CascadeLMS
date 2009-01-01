class AddAutomaticTurninFileFlag < ActiveRecord::Migration
  def self.up
     add_column( :assignment_documents, :add_to_all_turnins, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :assignment_documents, :add_to_all_turnins )
  end
end
