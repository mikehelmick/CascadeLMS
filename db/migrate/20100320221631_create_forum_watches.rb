class CreateForumWatches < ActiveRecord::Migration
  def self.up
    create_table :forum_watches, :id => false do |t|
      t.column :forum_topic_id, :int, :null => false
      t.column :user_id, :int, :null => false

      t.timestamps
    end
    add_index(:forum_watches, [:forum_topic_id, :user_id], :unique => true)
  end

  def self.down
    drop_table :forum_watches
  end
end
