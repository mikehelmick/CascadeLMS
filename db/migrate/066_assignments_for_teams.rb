class AssignmentsForTeams < ActiveRecord::Migration
  def self.up
    add_column( :assignments, :team_project, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :assignments, :team_project )
  end
end
