require 'BasicAuthentication'
require 'LdapAuthentication'

class IndexController < ApplicationController
  
  before_filter :check_login, :except => [ :logout, :credits ]
  before_filter :set_title
  
  def index
    @user = User.new
    if params[:out].eql?('out')
      flash[:notice] = "You have been logged out."
    elsif params[:out].eql?('exp')
      flash[:notice] = "Your session has expired due to inactivity, please log in again."
    end
  end
  
  def credits
  end
  
  def login
    @user = User.new( params[:user] )
    
    if @user.password.nil? || @user.password.eql?('') 
      @login_error = 'You must enter a password.'
      render :action => 'index'
      return
    end
    
    authenticate( @user )
  end
  
  def expired
    reset_session
    redirect_to :action => 'index', :out => 'exp'
  end
  
  def logout
    reset_session
    redirect_to :action => 'index', :out => 'out'
  end
  
  def check_login
    return true if session[:user].nil?
    redirect_to :controller => '/home'
    return false
  end
  
  def set_title
    @title = @app['title']
  end
  
  private :check_login, :set_title
  
end
