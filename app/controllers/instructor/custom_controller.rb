# Controller for views related to customizing entries that we origionally 
# more specific to computer science
#
# This includes journal tasks and rubric levels
class Instructor::CustomController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    
    redirect_to :controller => '/instructor/index', :course => @course, :action => nil, :id => nil
  end
  
  def journals
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_settings' )    

    load_journal_info()
    
    @title = "Customze Journal Settings for '#{@course.title}'"
  end
  
  def add_task
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_settings' )    
    
    @journal_task = JournalTask.new
    @journal_task.task = params['journal_task']
    @journal_task.course_id = @course.id
    @journal_task.save
    
    load_journal_info()
    
    render :layout => false, :partial => 'tasks'
  end
  
  def del_task
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_settings' )    
    
    @journal_task = JournalTask.find( params[:id] )
    unless @journal_task.nil?
      if @journal_task.course_id == @course.id
        @journal_task.destroy
      end
    end
    
    render :nothing => true
  end
  
  def add_stop_reason
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_settings' )    
    
    @journal_stop_reason = JournalStopReason.new
    @journal_stop_reason.reason = params['journal_stop_reason']
    @journal_stop_reason.course_id = @course.id
    @journal_stop_reason.save
    
    load_journal_info()
    
    render :layout => false, :partial => 'stop_reasons'
  end
  
  def del_stop_reason
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_settings' )    
    
    @journal_stop_reason = JournalStopReason.find( params[:id] )
    unless @journal_stop_reason.nil?
      if @journal_stop_reason.course_id == @course.id
        @journal_stop_reason.destroy
      end
    end
    
    render :nothing => true    
  end
  
  
  private
  
  def load_journal_info()
      @journal_tasks = JournalTask.for_course( @course )
      @journal_stop_reasons = JournalStopReason.for_course( @course )    

      @jt_in_use = Hash.new
      @journal_tasks.each do |jt|
        @jt_in_use[jt.id] = JournalEntryTask.count( :conditions => ["journal_task_id = ?", jt.id] ) > 0
      end

      @jsr_in_use = Hash.new
      @journal_stop_reasons.each do |jsr|
        @jsr_in_use[jsr.id] = JournalEntryStopReason.count( :conditions => ["journal_stop_reason_id = ?", jsr.id] ) > 0
      end
  end
  
end
