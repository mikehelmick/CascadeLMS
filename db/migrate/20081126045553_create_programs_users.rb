class CreateProgramsUsers < ActiveRecord::Migration
  def self.up
    create_table :programs_users do |t|
      t.column :user_id, :integer, :null => false
      t.column :program_id, :integer, :null => false

      t.column :program_manager, :boolean, :null => false, :default => true
      t.column :program_auditor, :boolean, :null => false, :default => false

      t.timestamps
    end
    add_index(:programs_users, [:user_id, :program_id], :unique => true)
  end

  def self.down
    drop_table :programs_users
  end
end
