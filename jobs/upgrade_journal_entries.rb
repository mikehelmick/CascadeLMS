# A job that upgrades journal entries

class UpgradeJournalEntries
  
  def initialize( course_id, type, mappings )
    @course_id = course_id
    @type = type
    
    @mappings = Hash.new
    i = 0
    while i < mappings.size
      @mappings[mappings[i].to_i] = mappings[i+1].to_i
      i = i + 2 
    end
  end
  
  def execute()
    # load the course
    course = Course.find(@course_id)
    
    # instructors will be needed for notifications
    instructors = course.instructors
    
    assignments = course.assignments
    # for each assignment, look for each journal
    assignments.each do |assignment|
      # journals are easy to load
      journals = Journal.find(:all, :conditions => ["assignment_id = ?", assignment.id])
      
      # for each journal, we need to re-map tasks and stop reasons
      if @type.eql?("tasks")
        # Update the task mapping
        journals.each do |journal|
          @mappings.keys.each do |key|
            JournalEntryTask.update_all("journal_task_id = #{@mappings[key]}", ["journal_id = ? and journal_task_id = ?", journal.id, key])
          end
        end
        
        
      elsif @type.eql?("stop_reasons")
        # update the stop reasons
        journals.each do |journal|
          @mappings.keys.each do |key|
            JournalEntryStopReason.update_all("journal_stop_reason_id = #{@mappings[key]}", ["journal_id = ? and journal_stop_reason_id = ?", journal.id, key])
          end          
        end
      
      end
      
    end
    
    if @type.eql?("tasks")
      instructors.each do |user|
        notify( "Upgraded all journal entries in the course '#{course.title}' from generic tasks to course specific ones.  You can now edit journal settings from the instructor page.", user )
      end
    elsif @type.eql?("stop_reasons")
      instructors.each do |user|
        notify( "Upgraded all journal entries in the course '#{course.title}' from generic stop reasons to course specific ones.  You can now edit journal settings from the instructor page.", user )
      end
    end
  end
  
  def notify( text, user )
    notification = Notification.new
    notification.notification = text
    notification.user = user
    notification.link = nil
    notification.emailed = false
    notification.acknowledged = false
    notification.save
  end
  
end

# params
# course_id type mapping pairs
course_id = ARGV[0].to_i
type = ARGV[1]
  
upgrade = UpgradeJournalEntries.new( course_id, type, ARGV[2..-1] )
upgrade.execute
