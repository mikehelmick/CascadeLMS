class CreateRubricEntries < ActiveRecord::Migration
  def self.up
    create_table :rubric_entries do |t|
      t.column :assignment_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :rubric_id, :integer, :null => false
      
      t.column :full_credit, :boolean, :null => false, :default => false
      t.column :partial_credit, :boolean, :null => false, :default => false
      t.column :no_credit, :boolean, :null => false, :default => false

      t.column :comments, :text

      t.timestamps
    end
    
    add_index(:rubric_entries, [:assignment_id], :unique => false)
    add_index(:rubric_entries, [:user_id,:rubric_id], :unique => true)
  end

  def self.down
    drop_table :rubric_entries
  end
end
