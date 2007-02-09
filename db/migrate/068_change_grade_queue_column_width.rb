class ChangeGradeQueueColumnWidth < ActiveRecord::Migration
  def self.up
    change_column(:grade_queues, :message, :text)
  end

  def self.down
  end
end
