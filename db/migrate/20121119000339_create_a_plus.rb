class CreateAPlus < ActiveRecord::Migration
  def self.up
    create_table(:a_plus) do |t|
      t.column :item_id, :integer, :null => false
      t.column :user_id, :integer, :null => false

      t.timestamps
    end
    add_index(:a_plus, [:item_id])
    add_index(:a_plus, [:user_id])
    add_index(:a_plus, [:item_id, :user_id], :unique => true)
  end

  def self.down
    drop_table :a_plus
  end
end
