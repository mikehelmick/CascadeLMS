class AddUrlForDocuments < ActiveRecord::Migration
  def self.up
    add_column(:documents, :link, :boolean, :null => false, :default => false)
    add_column(:documents, :url, :text, :null => false)
  end

  def self.down
    execute <<-SQL
      delete from documents where link=1
    SQL
    remove_column(:documents, :link)
    remove_column(:documents, :url)
  end
end
