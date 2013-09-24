class CreateGithubServers < ActiveRecord::Migration
  def self.up
    create_table :github_servers do |t|
      t.column :name, :string, :null => false
      t.column :api_endpoint, :string, :null => false
      t.column :web_endpoint, :string, :null => false
      t.column :client_id, :string, :null => false
      t.column :secret_key, :string, :null => false
      t.column :active, :boolean, :null => false, :default => true
      t.timestamps
    end
    
    add_index(:github_servers, [:name], :unique => true, :name => 'item_comments_item_id_index')
  end

  def self.down
    drop_table :github_servers
  end
end
