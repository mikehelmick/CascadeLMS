require 'BasicAuthentication'
require 'LdapAuthentication'

class IndexController < ApplicationController
  
  before_filter :check_login, :except => [ :logout, :credits ]
  before_filter :set_title
  
  def index
    @user = User.new
    if params[:out].eql?('out')
      flash[:notice] = "You have been logged out."
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
