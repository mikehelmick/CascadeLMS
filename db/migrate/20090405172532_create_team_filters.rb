class CreateTeamFilters < ActiveRecord::Migration
  def self.up
    create_table :team_filters do |t|
      t.column :assignment_id, :integer, :null => false
      t.column :project_team_id, :integer, :null => false

      t.timestamps
    end
    
    add_index(:team_filters, [:assignment_id, :project_team_id], :unique => true)
  end

  def self.down
    drop_table :team_filters
  end
end
