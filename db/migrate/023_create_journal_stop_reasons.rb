class CreateJournalStopReasons < ActiveRecord::Migration
  def self.up
    create_table :journal_stop_reasons do |t|
      t.column :reason, :string
      t.column :course_id, :integer, :null => false, :default => 0
      # t.column :name, :string
    end
    
    JournalStopReason.create :reason => 'Do not know what to do next.', :course_id => 0
    JournalStopReason.create :reason => 'Done with the whole project.', :course_id => 0
    JournalStopReason.create :reason => 'Not done, but project is due now.', :course_id => 0
    JournalStopReason.create :reason => 'Need to do something unrelated to the project.', :course_id => 0
    JournalStopReason.create :reason => 'Hardware problem.', :course_id => 0
    JournalStopReason.create :reason => 'Other (describe in comments).', :course_id => 0
  end

  def self.down
    drop_table :journal_stop_reasons
  end
end
