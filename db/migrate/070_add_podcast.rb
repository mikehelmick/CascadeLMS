class AddPodcast < ActiveRecord::Migration
  def self.up
    add_column( :documents, :podcast_folder, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :documents, :podcast_folder )
  end
end
