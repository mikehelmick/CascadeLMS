class CreateTeamEmails < ActiveRecord::Migration
  def self.up
    create_table :team_emails do |t|
      t.column :project_team_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      
      t.column :subject, :string, :null => false
      t.column :message, :text, :null => false
      t.column :created_at, :timestamp, :null => false
      
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :team_emails
  end
end
