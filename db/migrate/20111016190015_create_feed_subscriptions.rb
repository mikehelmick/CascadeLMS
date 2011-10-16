class CreateFeedSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :feed_subscriptions do |t|
      t.column :feed_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :send_email, :boolean, :null => false, :default => true
      t.timestamps
    end
    add_index(:feed_subscriptions, [:feed_id])
    add_index(:feed_subscriptions, [:user_id])
    
    ## Also add in the emailed flag
    add_column( :item_shares, :emailed, :boolean, :null => false, :default => false )
  end

  def self.down
    remove_column( :item_shares, :emailed )

    drop_table :feed_subscriptions
  end
end
