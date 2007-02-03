class CreateTeamMembers < ActiveRecord::Migration
  def self.up
    create_table :team_members do |t|
      t.column :project_team_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :course_id, :integer, :null => false
      # t.column :name, :string
    end
    
    add_index(:team_members, [:user_id,:course_id], :unique => false)
  end

  def self.down
    drop_table :team_members
  end
end
