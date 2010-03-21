class JournalField < ActiveRecord::Base
  set_primary_key 'assignment_id'
  belongs_to :assignment
  
  def copy_from( from )
    self.start_time = from.start_time
    self.end_time = from.end_time
    self.interruption_time = from.interruption_time
    self.completed = from.completed
    self.task = from.task
    self.reason_for_stopping = from.reason_for_stopping
    self.comments = from.comments
  end
  
end
