class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.column :user_id, :integer, :null => true
      t.column :course_id, :integer, :null => true
    end
    add_index(:feeds, [:user_id], :unique => true)
    add_index(:feeds, [:course_id], :unique => true)
  end

  def self.down
    drop_table :feeds
  end
end
