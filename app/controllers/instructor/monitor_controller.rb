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
    
    render :layout => 'noright'
  end
  
  def agfailed
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    @items = GradeQueue.find(:all, :conditions => ["failed = ?", true], :order => 'created_at asc' ) 
    @items = Array.new if @items.nil?
    
    render :layout => 'noright'
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
    
    render :layout => false
  end
  
  private
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
    @title = "Application Monitor"
  end
  
end
