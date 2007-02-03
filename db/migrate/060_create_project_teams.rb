class CreateProjectTeams < ActiveRecord::Migration
  def self.up
    create_table :project_teams do |t|
      t.column :course_id, :integer, :null => false
      t.column :team_id, :string, :null => false
      t.column :name, :string, :null => false
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :project_teams
  end
end
