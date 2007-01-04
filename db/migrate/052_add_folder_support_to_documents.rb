class AddFolderSupportToDocuments < ActiveRecord::Migration
  def self.up
    add_column( :documents, :document_parent, :integer, :null => false, :default => 0 )
    add_column( :documents, :folder, :boolean, :null => false, :default => false )
    
  end

  def self.down
    remove_column( :documents, :folder )
    remove_column( :documents, :document_parent )
  end
end
