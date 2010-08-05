class CreateCourseTwitters < ActiveRecord::Migration
  def self.up
    create_table :course_twitters do |t|
      t.column :course_id, :int, :null => false
      t.column :twitter_enabled, :boolean, :null => false, :default => false
      t.column :auth_success, :boolean, :null => false, :default => false
      t.column :request_token, :string, :null => false
      t.column :request_secret, :string, :null => false
      t.column :auth_url, :string, :null => false
      t.column :access_token, :string, :null => true
      t.column :access_secret, :string, :null => true
      t.column :twitter_name, :string, :null => true
      t.column :twitter_id, :string, :null => true
      t.column :auth_code, :string, :null => true
      
      t.timestamps
    end
    
    add_index(:course_twitters, [:course_id], :unique => true)
  end

  def self.down
    drop_table :course_twitters
  end
end
