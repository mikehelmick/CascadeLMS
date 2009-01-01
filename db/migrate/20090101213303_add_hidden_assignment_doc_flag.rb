class AddHiddenAssignmentDocFlag < ActiveRecord::Migration
  def self.up
     add_column( :assignment_documents, :keep_hidden, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :assignment_documents, :keep_hidden )
  end
end
