#--
# Controller for the post-login/home page for users#
#
# Also maintains the account information page for systems that use 'basic' auth 
#
# Copyright 2006-2007 (c) Mike Helmick
#++
class HomeController < ApplicationController
  
  before_filter :ensure_logged_in
  
  def initialize()
    @title = "CascadeLMS"
  end
  
  # Some test code for background jobs
  #def test
  #  id = params[:id] 
  #  id = 10 if id.nil?
  #  Bj.submit "./jobs/test_job.rb #{id}"
  #  redirect_to :controller => '/home', :action => nil, :id => nil
  #end
  
  def index
    set_tab
    
    @title = "Home for #{@user.display_name}"
    @announcements = Announcement.current_announcements
    @courses = @user.courses_in_term( @term )

    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @feed_id = @user.feed.id
    @pages, @feed_items = @user.feed.load_items(@user, 25, @page)
    
    @notifications = Notification.find(:all, :conditions => ["user_id = ? and acknowledged = ? and view_count < ?", @user, false, 5], :order => "updated_at desc" )
    begin
      @notifications.each do |notification|
        notification.view_count = notification.view_count + 1
        notification.save
      end
    rescue
    end
    
    if @user.auditor
      @programs = @user.programs_under_audit()
      @audit_term = @term
    end
    maybe_run_publisher(false)
    
    respond_to do |format|
      format.html
      format.xml { 
        @other_courses = @user.courses
        @other_courses.sort! { |x,y| y.term.term <=> x.term.term }
        @other_courses.delete_if { |x| x.term.id == @term.id }
        
        render :layout => false 
      }
    end
  end

  def feeds
    set_tab
    @title = "Manage Feeds"
    @breadcrumb.text = 'Manage Feeds'
  end
  
  def reorder
    set_tab
    
    @title = "Home for #{@user.display_name}"
    @announcements = Announcement.current_announcements
    @courses = @user.courses_in_term( @term )
  end
  
  def sort_courses
    @courses = @user.courses_in_term( @term )
    
    # get the outcomes at this level
    CoursesUser.transaction do
      @courses.each do |cu|
        cu.position = params['course-order'].index( cu.id.to_s ) + 1
        cu.save
      end
    end
    
    render :nothing => true
  end
  
  def acknowledge
    notification = Notification.find( params[:id] )
    unless notification.nil?
      if notification.user_id == @user.id
        notification.acknowledged = true
        notification.save
      end
    end
    
    
    render :nothing => true
  end
  
  def courses
    set_tab
    
    @title = "All courses for #{@user.display_name}"
    
    @courses = @user.courses
    @courses.sort! { |x,y| y.term.term <=> x.term.term }
  end
  
  def account
    return unless ensure_basic_auth
    
    @confirm = ''

    @show_change_password = @app['authtype'].eql?('basic')
    
    
    ## for the right display
    set_tab
    @courses = @user.courses_in_term( @term )
    @title = "Your Account Information"
  end
  
  def account_update
    return unless ensure_not_ldap()
    
    ## for the right display
    set_tab
    @courses = @user.courses_in_term( @term )
    @title = "Your Account Information"
    
    # We're not using the active record update functionality - that way we can't hack extra changes
    @user.preferred_name = params[:preferred_name]
    @user.phone_number = params[:phone_number]
    @user.office_hours = params[:office_hours]
    @user.save
    
    requirePasswordValid = !'shibboleth'.eql?(@app['authtype'])
    unless @user.email.eql?( params[:email] )
      unless @user.change_email( params[:email], params[:password], requirePasswordValid)
        return bail( 'Incorrect password entered, email address has not been changed.' )
      end
      @user.save
      flash[:notice] = "Your email address has been updated."
    end

    # Not all authentication types allow the password to be changed in the application.
    if requirePasswordValid
      unless params[:new_password].nil? || params[:new_password].eql?('') 
        unless @user.valid_password?(params[:password])
          return bail('Current password incorrect, password has not been changed')
        end
        unless params[:new_password].eql?( params[:new_password_confirm] )
          return bail('New password and its confirmation do not match.  Password has not been changed.')
        end

        @user.update_password( params[:new_password] )
        @user.save
        flash[:notice] = "#{flash[:notice]} Your password has been updated."
      end
    end
    
    redirect_to :action => 'account'
  end
  
  private
  
  def bail( message )
    flash[:badnotice] = message
    redirect_to :action => 'account'
    true
  end
  
  def set_tab
    @tab = 'home'
    @breadcrumb = Breadcrumb.new
  end
  
end
