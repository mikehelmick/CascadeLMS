class CreateQuizAttempts < ActiveRecord::Migration
  def self.up
    create_table :quiz_attempts do |t|
      t.column :quiz_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      
      t.column :save_count, :integer, :null => false, :defualt => 0
      
      t.column :completed, :boolean, :null => false, :default => false
      t.column :score, :float
      
      t.timestamps
    end
    
    add_index(:quiz_attempts, [:quiz_id], :unique => false)
    add_index(:quiz_attempts, [:user_id], :unique => false)
    
  end

  def self.down
    drop_table :quiz_attempts
  end
end
