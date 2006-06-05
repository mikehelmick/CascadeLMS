class CreateJournalFields < ActiveRecord::Migration
  def self.up
    create_table :journal_fields, :id => false do |t|
      t.column :assignment_id, :integer
      
      t.column :start_time, :boolean, :null => false, :default => true
      t.column :end_time, :boolean, :null => false, :default => true
      t.column :interruption_time, :boolean, :null => false, :default => true
      t.column :completed, :boolean, :null => false, :default => true
      t.column :task, :boolean, :null => false, :default => true
      t.column :reason_for_stopping, :boolean, :null => false, :default => true
      t.column :comments, :boolean, :null => false, :default => true
      # t.column :name, :string
    end
    add_index(:journal_fields, [:assignment_id], :unique => true)
  end

  def self.down
    drop_table :journal_fields
  end
end
