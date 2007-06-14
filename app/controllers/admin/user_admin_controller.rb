#+
# Controller for the admin screen / user admin
#
# Copyright (c) 2007 - Mike Helmick
#-
class Admin::UserAdminController < ApplicationController
  
  before_filter :ensure_logged_in, :ensure_admin
  
  def index
    session[:searchby] = 'uniqueid'
    session[:searchletter] = ''
    set_tab
  end

  def searchby
    session[:searchby] = params[:id]
    session[:searchletter] = ''
    render(:layout => false, :partial => 'controls')
  end
  
  def toggle_instructor
    @user = User.find(params[:id])
    @user.toggle_instructor
    @user.save
    render(:layout => false)
  end
  
  def toggle_admin
    @user = User.find(params[:id])
    @user.toggle_admin
    @user.save
    render(:layout => false)    
  end
  
  def toggle_enabled
    @user = User.find(params[:id])
    @user.toggle_enabled
    @user.save
    render(:layout => false)    
  end
  
  def listbyletter
    letter = params[:id].downcase
    letter_up = letter.upcase
    session[:searchletter] = letter_up
    
    field = 'uniqueid'
    field = 'first_name' if !session[:searchby].nil? && session[:searchby].eql?('firstname')
    field = 'last_name' if !session[:searchby].nil? && session[:searchby].eql?('lastname')
    
    #@users = User.find(:all, :conditions => ["#{field} like 'h%%' or #{field} like 'a%%' order by #{field} asc" ] )
    @users = User.find_by_sql "SELECT * FROM users WHERE #{field} like '#{letter}%' or #{field} like '#{letter_up}?' order by #{field} asc"
    render(:layout => false, :partial => 'userlist')
  end
  
  def new
    return unless ensure_basic_auth
    set_tab
    
    @new_user = User.new
  end
  
  def create
    return unless ensure_basic_auth
    set_tab
    
    @new_user = User.new(params[:new_user])
    @new_user.activation_token = User.gen_token
    @new_user.password = User.gen_token(1024) ### if they guess this  -- then you win
    if @new_user.save
      # send email
      
      link = url_for :controller => '/index', :action => 'activate', :id => @new_user.id, :seq => @new_user.activation_token, :only_path => false
      
      Notifier::deliver_send_create( @new_user, @user, link, @app['organization'] )
      
      flash[:notice] = "New user '#{@new_user.uniqueid}' has been created."
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end
  
  def edit
    return unless ensure_basic_auth
    set_tab
    
    begin
      @new_user = User.find(params[:id])
    rescue
      flash[:badnotice] = 'Invalid user requested.'
      redirect_to :action => 'index', :id => nil
    end
  end
  
  def update
    return unless ensure_basic_auth
    set_tab
    
    @new_user = User.find(params[:id])
    
    if @new_user.update_attributes(params[:new_user])
      flash[:notice] = "User '#{@new_user.uniqueid}' has been updated."
      redirect_to :action => 'index', :id => nil
    
    else
      flash[:badnotice] = 'There was an error saving your changes.'
      render :action => 'edit'
    end
  end
  
  private
  
  def ensure_basic_auth
    unless @app['authtype'].eql?('basic')
      flash[:badnotice] = "You can not manually create users when using basic authentication.  With LDAP authentication enabled, new users must be created in the LDAP directory tree."
      redirect_to :action => 'index'
      return false
    end
    return true
  end
  
  def set_tab
     @tab = 'administration'
     @title = 'User Admin'
  end
  
end
