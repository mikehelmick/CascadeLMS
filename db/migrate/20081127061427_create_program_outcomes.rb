class CreateProgramOutcomes < ActiveRecord::Migration
  def self.up
    create_table :program_outcomes do |t|
      t.column :program_id, :integer
      t.column :outcome, :text, :null => false
      t.column :position, :integer
      
      t.timestamps
    end
  end

  def self.down
    drop_table :program_outcomes
  end
end
