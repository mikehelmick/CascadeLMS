class AddGitHubToAssignments < ActiveRecord::Migration
  def self.up
    add_column(:assignments, :use_github, :boolean, :null => false, :default => false)
    add_column(:assignments, :github_organization, :string, :null => true)
    add_column(:assignments, :github_pattern, :string, :null => true)
  end

  def self.down
    remove_column(:assignments, :use_github)
    remove_column(:assignments, :github_organization)
    remove_column(:assignments, :github_pattern)
  end
end
