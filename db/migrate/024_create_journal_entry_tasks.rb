class CreateJournalEntryTasks < ActiveRecord::Migration
  def self.up
    create_table :journal_entry_tasks, :id => false do |t|
      t.column :journal_id, :integer
      t.column :journal_task_id, :integer
      # t.column :name, :string
    end
    add_index(:journal_entry_tasks, [:journal_id, :journal_task_id], :unique => true)
  end

  def self.down
    drop_table :journal_entry_tasks
  end
end
