class CreateTeamDocuments < ActiveRecord::Migration
  def self.up
    create_table :team_documents do |t|    
      t.column :project_team_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      
      t.column :filename, :string, :null => false
      t.column :content_type, :string, :null => false
      t.column :extension, :string
      t.column :size, :string
      t.column :created_at, :datetime, :null => false
      
    end
  end

  def self.down
    drop_table :team_documents
  end
end
