class Instructor::MonitorController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    flash[:notice] = 'Invalid page requested'
    redirect_to :controller => '/instructor/index', :course => @course
  end
  
  
  def agqueue
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    @items = GradeQueue.find(:all, :conditions => ["serviced = ?", false], :order => 'created_at asc' )   
    
    @jobs = Bj.table.job.find(:all, :conditions => ["state != ?", "finished"], :order => 'priority asc, submitted_at asc')
    
    set_breadcrumb().text = 'AutoGrade Queue'
  end
  
  def agfailed
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    @items = GradeQueue.find(:all, :conditions => ["failed = ?", true], :order => 'created_at asc' ) 
    @items = Array.new if @items.nil?
    
    set_breadcrumb().text = 'AutoGrade Failures'
  end
  
  def agclear
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    return unless ensure_admin
      
    @items = GradeQueue.find(:all, :conditions => ["failed = ?", true], :order => 'created_at asc' ) 
    GradeQueue.transaction do
      @items.each do |item| 
        item.serviced = true
        item.acknowledged = true
        item.queued = true
        item.failed = false
        item.message = "This record has been manually marked a success."
        item.save
      end
    end
      
    flash[:notice] = 'Cleared all failed AG entries.'
    redirect_to :action => 'agfailed', :course => @course    
  end
  
  def reset_ag_item
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    @item = GradeQueue.find( params[:id] )
    
    @item.serviced = false
    @item.acknowledged = false
    @item.queued = false
    @item.failed = false
    @item.message = "This record has been scheduled for reprocessing."
    @item.save
    AutoGradeHelper.schedule_job( @item.id )
    
    render :layout => false
  end
  
  def mark_ag_finished
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    @item = GradeQueue.find( params[:id] )
    
    @item.serviced = true
    @item.acknowledged = true
    @item.queued = true
    @item.failed = true
    @item.message = "Manually failed by #{@user.display_name}."
    @item.save
    
    render :layout => false    
  end
  
  private
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
    @title = "Application Monitor"
  end

  def set_breadcrumb()
    @breadcrumb = Breadcrumb.for_course(@course, true)
    return @breadcrumb
  end
end
