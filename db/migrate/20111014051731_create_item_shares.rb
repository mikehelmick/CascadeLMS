class CreateItemShares < ActiveRecord::Migration
  def self.up
    create_table(:item_shares) do |t|
      t.column :item_id, :integer, :null => false
      t.column :user_id, :integer, :null => true
      t.column :course_id, :integer, :null => true
    end
    add_index(:item_shares, [:item_id])
  end

  def self.down
    drop_table :item_shares
  end
end
