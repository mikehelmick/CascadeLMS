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
  
  def set_tab
     @tab = 'administration'
  end
  
end
