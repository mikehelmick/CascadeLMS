class AddGitHubRepositoryToUserTurnin < ActiveRecord::Migration
  def self.up
    add_column(:user_turnins, :github_repository, :text, :null => true)
    add_column(:user_turnins, :git_revision, :text, :null => true)
  end

  def self.down
    remove_column(:user_turnins, :github_repository)
    remove_column(:user_turnins, :git_revision)
  end
end
