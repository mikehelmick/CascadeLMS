class CreateJournalTasks < ActiveRecord::Migration
  def self.up
    create_table :journal_tasks do |t|
      t.column :task, :string
      t.column :course_id, :integer, :null => false, :default => 0
      # t.column :name, :string
    end
    
    JournalTask.create :task => 'Designing', :course_id => 0
    JournalTask.create :task => 'Coding', :course_id => 0
    JournalTask.create :task => 'Project-related reading', :course_id => 0
    JournalTask.create :task => 'Debugging', :course_id => 0
    JournalTask.create :task => 'Testing', :course_id => 0
    JournalTask.create :task => 'Talking to someone about the project (TA/Instructor/Other Student)', :course_id => 0
  end

  def self.down
    drop_table :journal_tasks
  end
end
