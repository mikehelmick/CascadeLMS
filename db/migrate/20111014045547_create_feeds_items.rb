class CreateFeedsItems < ActiveRecord::Migration
  def self.up
    create_table(:feeds_items) do |t|
      t.column :feed_id, :integer, :null => false
      t.column :item_id, :integer, :null => false

      t.column :timestamp, :datetime
    end
    add_index(:feeds_items, [:feed_id, :item_id], :unique => true)
    add_index(:feeds_items, [:feed_id])
  end

  def self.down
    drop_table :feeds_items
  end
end
