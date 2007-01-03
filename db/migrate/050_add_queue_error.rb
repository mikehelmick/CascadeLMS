class AddQueueError < ActiveRecord::Migration
  def self.up
    add_column( :grade_queues, :failed, :boolean, :null => false, :default => false )
    add_column( :grade_queues, :message, :string )
  end

  def self.down
    remove_column( :grade_queues, :failed )
    remove_column( :grade_queues, :message )
  end
end
