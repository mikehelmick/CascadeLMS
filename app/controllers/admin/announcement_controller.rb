class Admin::AnnouncementController < ApplicationController

  before_filter :ensure_logged_in, :ensure_admin
  # don't set on the AJAX calls
  before_filter :set_tab

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @announcements = Announcement.find( :all, :order => "end desc" )
  end

  def show
    @announcement = Announcement.find(params[:id])
  end

  def new
    @announcement = Announcement.new
  end

  def create
    @announcement = Announcement.new(params[:announcement])
    if @announcement.save
      flash[:notice] = 'Announcement was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @announcement = Announcement.find(params[:id])
  end

  def update
    @announcement = Announcement.find(params[:id])
    if @announcement.update_attributes(params[:announcement])
      flash[:notice] = 'Announcement was successfully updated.'
      redirect_to :action => 'show', :id => @announcement
    else
      render :action => 'edit'
    end
  end

  def destroy
    Announcement.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  def set_tab 
    @title = 'System Announcements'
    @tab = 'administration'
    @current_term = Term.find_current
    @announcements = Announcement.current_announcements
  end
end
