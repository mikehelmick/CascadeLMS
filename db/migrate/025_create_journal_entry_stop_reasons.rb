class CreateJournalEntryStopReasons < ActiveRecord::Migration
  def self.up
    create_table :journal_entry_stop_reasons, :id => false do |t|
      t.column :journal_id, :integer
      t.column :journal_stop_reason_id, :integer
      # t.column :name, :string
    end
    add_index(:journal_entry_stop_reasons, [:journal_id, :journal_stop_reason_id], :unique => true)
  end

  def self.down
    drop_table :journal_entry_stop_reasons
  end
end
