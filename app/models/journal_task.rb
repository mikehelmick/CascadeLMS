class JournalTask < ActiveRecord::Base
  
  validates_presence_of :task
  
  def JournalTask.for_course( course )
    tasks = JournalTask.find(:all, :conditions => ["course_id = ?", course.id], :order => 'task asc')
    if tasks.length == 0 
      tasks = Array.new
      
      params = Array.new
      params << "tasks"
      
      # initialize from default
      default = JournalTask.find(:all, :conditions => ["course_id = ?", 0], :order => 'task asc')
      default.each do |defaultTask|
        newTask = JournalTask.new
        newTask.task = defaultTask.task
        newTask.course_id = course.id
        newTask.save
        tasks << newTask
        
        params << defaultTask.id
        params << newTask.id
      end
      Bj.submit "./script/runner ./jobs/upgrade_journal_entries.rb #{course.id} #{params.join(' ')}"
    end
    return tasks
  end
  
  
end
