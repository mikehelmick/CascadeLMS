class GroupTurnins < ActiveRecord::Migration
  def self.up
    add_column( :user_turnins, :project_team_id, :integer, :null => true )
    
    add_column( :user_turnin_files, :user_id, :integer, :null => true )
  end

  def self.down
    remove_column( :user_turnins, :project_team_id )
    
    remove_column( :user_turnin_files, :project_team_id )
  end
end
