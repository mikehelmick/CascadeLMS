class AddBatch < ActiveRecord::Migration
  def self.up
    add_column( :grade_queues, :batch, :string, :null => true )
    
    add_index(:grade_queues, :batch, :unique => false)
  end

  def self.down
    remove_column( :grade_queues, :batch )
  end
end
