class Journal < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :user
  
  has_and_belongs_to_many :journal_tasks, :join_table => 'journal_entry_tasks'
  has_and_belongs_to_many :journal_stop_reasons, :join_table => 'journal_entry_stop_reasons'
  
  def validate
    # THIS SHOULD NEVER HAPPEN IN *NORMAL* APPLICATION FLOW
    errors.add_to_base("This assignment does not have journals enabled.") unless assignment.enable_journal
    
    if assignment.journal_field.start_time && assignment.journal_field.end_time
      errors.add_to_base("Start time must be before end time") if start_time >= end_time
    end
    
    if assignment.journal_field.interruption_time
      begin
        x = Integer( self.interruption_time )
      rescue
      end
      errors.add_to_base('Interruption time must be an integer (time in minutes).') if x.nil?
    end
    
  end
  
  def completed_text
    if completed
      "Yes"
    else
      "No"
    end
  end
  
  def before_save
    self.interruption_time = 0 if self.interruption_time.nil?
  end
  
  def before_destroy
    JournalEntryTask.delete_all ( ["journal_id = ?", self.id ] )
    JournalEntryStopReason.delete_all( ["journal_id = ?", self.id ] )
  end
  
  def has_task?( task_id )
    journal_tasks.each { |x| return true if x.id == task_id }
    return false
  end
  
  def has_stop_reason?( stop_reason_id )
    journal_stop_reasons.each { |x| return true if x.id == stop_reason_id }
    return false
  end
   
end
