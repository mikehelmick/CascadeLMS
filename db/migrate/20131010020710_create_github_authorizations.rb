class CreateGithubAuthorizations < ActiveRecord::Migration
  def self.up
    create_table :github_authorizations do |t|
      t.column :user_id, :integer, :null => false
      t.column :github_server_id, :integer, :null => false
      t.column :access_token, :string, :null => false
      t.timestamps
    end
    add_index(:github_authorizations, [:user_id, :github_server_id], :unique => true, :name => 'user_id_github_server_id')
  end

  def self.down
    drop_table :github_authorizations
  end
end
