class CreateAPlus < ActiveRecord::Migration
  def self.up
    create_table(:a_plus, :id => false, :primary_key => 'item_id, user_id' ) do |t|
      t.column :item_id, :integer, :null => false
      t.column :user_id, :integer, :null => false

      t.timestamps
    end
    add_index(:a_plus, [:item_id])
    add_index(:a_plus, [:user_id])
  end

  def self.down
    drop_table :a_plus
  end
end
