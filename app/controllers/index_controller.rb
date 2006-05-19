require 'BasicAuthentication'
require 'LdapAuthentication'

class IndexController < ApplicationController
  
  layout 'application'
  before_filter :check_login, :except => [ :logout, :credits ]
  
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
    
    auth = BasicAuthentication.new()
    auth = LdapAuthentication.new( @app ) if @app['authtype'].downcase.eql?('ldap')
    
    begin
      @user = auth.authenticate( @user.uniqueid, @user.password )
      session[:user] = User.find( @user.id )
      redirect_to :controller => 'home'
    rescue SecurityError => doh
      @login_error = doh.message
      @user.password = ''
      render :action => 'index'
    end
    
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
  
  private :check_login
  
end
