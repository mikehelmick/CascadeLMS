class JournalStopReason < ActiveRecord::Base
  
  def JournalStopReason.for_course( course )
    reasons = JournalStopReason.find(:all, :conditions => ["course_id = ?", course.id], :order => 'reason asc')
    
    if reasons.size == 0 
      reasons = Array.new
      
      params = Array.new
      params << "stop_reasons"
      
      # initialize from default
      default = JournalStopReason.find(:all, :conditions => ["course_id = ?", 0], :order => 'reason asc')
      default.each do |defaultReason|
        newReason = JournalStopReason.new
        newReason.reason = defaultReason.reason
        newReason.course_id = course.id
        newReason.save
        reasons << newReason
        
        params << defaultReason.id
        params << newReason.id
      end
      Bj.submit "./script/runner ./jobs/upgrade_journal_entries.rb #{course.id} #{params.join(' ')}"
    end
    return reasons
  end
  
end
