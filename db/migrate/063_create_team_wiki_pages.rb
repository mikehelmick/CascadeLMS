class CreateTeamWikiPages < ActiveRecord::Migration
  def self.up
    create_table :team_wiki_pages do |t|
      t.column :project_team_id, :integer, :null => false
      t.column :page, :string, :null => false
      
      t.column :content, :text, :null => false
      t.column :content_html, :text, :null => false
      
      t.column :created_at, :timestamp, :null => false
      t.column :updated_at, :timestamp, :null => false
      t.column :user_id, :integer, :null => false
      
      t.column :revision, :integer, :null => false, :default => 1
      
    end
    
    add_index(:team_wiki_pages, [:project_team_id,:page,:revision], :unique => true)
  end

  def self.down
    drop_table :team_wiki_pages
  end
end
