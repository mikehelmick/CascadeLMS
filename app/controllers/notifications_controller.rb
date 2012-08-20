class NotificationsController < ApplicationController
  before_filter :ensure_logged_in, :except => [ :get_count ]

  def index
    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @note_pages = Paginator.new self, Notification.count(:conditions => ["user_id = ?", @user.id]), 30, @page
    @notifications = Notification.find(:all, :conditions => ['user_id = ?', @user.id], :order => 'created_at DESC', :limit => 30, :offset => @note_pages.current.offset)

    set_title
  end

  def get_count
    ensure_logged_in(false)
    rtn = Hash.new
    rtn['count'] = @user.notification_count
    
    render :json => rtn
  end

  def panel
    @notifications = Notification.find(:all, :conditions => ["user_id = ?", @user.id], :order => "created_at desc", :limit => "5")
    
    render :layout => false
  end

  def ack
    note = Notification.find(:first, :conditions => ["user_id = ? and id = ?", @user.id, params[:id]])
    unless note.nil?
      note.acknowledged = true
      note.save
    end
    
    render :json => 'ok'
  end

  def mark_read
    Notification.update_all("acknowledged = 1", ["user_id = ? and acknowledged = ?", @user.id, false])

    redirect_to :action => 'index'
  end

  def set_title
    @title = "Your Notifications"
    @breadcrumb = Breadcrumb.new
    @breadcrumb.text = 'Notifications'
  end

  private :set_title
  
end
