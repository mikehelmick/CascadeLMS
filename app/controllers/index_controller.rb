require 'BasicAuthentication'
require 'LdapAuthentication'

class IndexController < ApplicationController
  
  before_filter :check_login, :except => [ :logout, :credits, :api, :logged_in, :tickle, :shibboleth ]
  before_filter :set_title
  
  def index
    @authtype = @app['authtype']
     
    @user = User.new
    if params[:out].eql?('out')
      flash[:notice] = "You have been logged out."
    elsif params[:out].eql?('exp')
      flash[:notice] = "Your session has expired due to inactivity, please log in again."
    end

    showAds()
    render :layout => 'login'
  end

  def shibboleth
    @new_user = shibboleth_authenticate()

    if !@new_user
      # Logged in, send to home
      redirect_to :controller => '/home'
    else
      render :layout => 'transitional'
    end
  end

  def tickle
    maybe_run_publisher(true)
  end
  
  def logged_in
    load_user_if_logged_in()
    loggedIn = false
    unless @user.nil?
      loggedIn = session_valid?(false)
    end
    
    rtn = Hash.new
    rtn['valid'] = loggedIn
    
    render :json => rtn
  end

  def credits
    load_user_if_logged_in()
    render :layout => 'noright'
  end
  
  def api
    load_user_if_logged_in
    @title = "CascadeLMS - REST API"
    
    showAds()
    render :layout => 'login'
  end
  
  def login
    @user = User.new( params[:user] )
    
    if @user.password.nil? || @user.password.eql?('') 
      @login_error = 'You must enter a password.'
      render :action => 'index', :layout => 'login'
      return
    end
    
    authenticate( @user )   
  end
  
  def expired
    redirect_uri = session[:post_login]
    reset_session
    session[:post_login] = redirect_uri
    redirect_to :action => 'index', :out => 'exp'
  end

  def timeout
    reset_session
    redirect_to :action => 'index', :out => 'exp'
  end
  
  def logout
    reset_session
    redirect_to :action => 'index', :out => 'out'
  end

  def register
    return unless ensure_basic_auth()

    @new_user = User.new
    render :layout => 'login'
  end

  def create
    return unless ensure_basic_auth()

    @new_user = User.new(params[:new_user])
    @new_user.activation_token = User.gen_token
    @new_user.password = User.gen_token(1024) ### Not a real password, basically impossible to guess
    # Double check the defualt are put in correctly.
    @new_user.instructor = false
    @new_user.admin = false
    @new_user.auditor = false

    unless valid_registration_domain(@new_user, @app['auth_self_registration_domain'])
      render :action => 'register', :layout => 'login'
      return
    end

    if @new_user.save
      # send email
      link = url_for :controller => '/index', :action => 'activate', :id => @new_user.id, :seq => @new_user.activation_token, :only_path => false
      
      send_user = User.new
      send_user.first_name = 'CascadeLMS'
      send_user.last_name = @app['organization']
      send_user.email = @app['email']
      
      Notifier::deliver_send_create( @new_user, send_user, link, @app['organization'] )
      
      flash[:notice] = "Please check your email for account activation instructions."
      redirect_to :action => 'index'
    else
      render :action => 'register', :layout => 'login'
    end
  end

  def forgot
    return unless ensure_basic_auth
    
    render :layout => 'login'
  end
  
  def send_forgot
    return unless ensure_basic_auth
    
    @act_user = nil
    if !nil_or_empty( params[:uniqueid] ) 
      @act_user = User.find(:first, :conditions => ['uniqueid = ?', params[:uniqueid] ] )
      
      unless @act_user.nil?
        @act_user.forgot_token = User.gen_token
        @act_user.save
        
        link = url_for :controller => '/index', :action => 'reset_password', :id => @act_user.id, :seq => @act_user.forgot_token, :only_path => false
        Notifier::deliver_send_recover( @act_user, @app['email'], link, @app['organization'] )
        
      end
      
      flash[:notice] = 'Check your email for password reset instructions.'
      redirect_to :controller => '/', :action => nil
      
    else
      flash[:badnotice] = 'You must enter either your username or email address.'
      redirect_to :action => 'forgot'
    end
    
  end
  
  def reset_password
    return unless ensure_basic_auth
    
    @act_user = User.find(:first, :conditions => ['id = ? and forgot_token = ?', params[:id], params[:seq] ] ) rescue @act_user = nil
    if @act_user.nil?
      flash[:badnotice] = 'The information you requested is invalid or does not exist, please verify the password reset link in your email.'
      redirect_to :controller => '/', :action => nil, :id => nil
      return false
    end
    
    render :layout => 'login'
    true
  end
  
  def confirm_reset
    return unless ensure_basic_auth

    @act_user = User.find(:first, :conditions => ['id = ? and forgot_token = ?', params[:id], params[:seq] ] ) rescue @act_user = nil
    if @act_user.nil?
      flash[:badnotice] = 'The information you requested is invalid or does not exist, please verify the password reset link in your email.'
      redirect_to :controller => '/', :action => nil, :id => nil
      return false
    end
    
    unless @act_user.email.eql?(params[:email])
      flash[:badnotice] = "Email address is invalid, your password has not been changed."
      redirect_to :controller => '/index', :action => 'reset_password', :id => @act_user.id, :seq => @act_user.forgot_token
      return
    end
    
    if params[:new_password].eql?( params[:new_password_confirm] ) 
      @act_user.update_password( params[:new_password] ) 
      
      if @act_user.save
        flash[:notice] = "Your password has been set, you may now log in."
        redirect_to :controller => '/', :action => nil, :id => nil
        
        
        begin
          @act_user.forgot_token = User.gen_token
          @act_user.save 
        rescue
          # if this fails - no big deal
        end
        return 
      
      else
        flash[:badnotice] = "There was an error setting your password, please try again."
        redirect_to :controller => '/index', :action => 'activate', :id => @act_user.id, :seq => @act_user.forgot_token
      end
      
    else    
      flash[:badnotice] = 'New password and its confirmation do not match.'
      render :action => 'reset_password'

    end
    
    render :layout => 'login'
  end

  def activate
    return unless ensure_basic_auth
    
    @act_user = User.find(:first, :conditions => ['id = ? and activation_token = ?', params[:id], params[:seq] ] ) rescue @act_user = nil
    
    if @act_user.nil?
      flash[:badnotice] = 'The information you requested is invalid or does not exist, please verify the account activation link in your email.'
      redirect_to :controller => '/', :action => nil, :id => nil
      return false
    
    elsif @act_user.activated
      flash[:notice] = 'Your account has already been activated.'
      redirect_to :controller => '/', :action => nil, :id => nil
      return false
    end
    
    render :layout => 'login'
    true
  end
  
  def confirm
    ## just call the activate function, same results
    @act_user = User.find(:first, :conditions => ['id = ? and activation_token = ?', params[:id], params[:seq] ] ) rescue @act_user = nil
    
    if @act_user.nil?
      flash[:badnotice] = 'The information you requested is invalid or does not exist, please verify the account activation link in your email.'
      redirect_to :controller => '/', :action => nil, :id => nil
      return false
    
    elsif @act_user.activated
      flash[:notice] = 'Your account has already been activated.'
      redirect_to :controller => '/', :action => nil, :id => nil
      return false
    end
    
    unless @act_user.email.eql?(params[:email])
      flash[:badnotice] = "Email address is invalid, your account has not been activated."
      redirect_to :controller => '/index', :action => 'activate', :id => @act_user.id, :seq => @act_user.activation_token
      return
    end
    
    if params[:new_password].eql?( params[:new_password_confirm] ) 
      @act_user.update_password( params[:new_password] ) 
      @act_user.activated = true
      if @act_user.save
        flash[:notice] = "Your password has been set, you may now log in."
        redirect_to :controller => '/', :action => nil, :id => nil
      
      else
        flash[:badnotice] = "There was an error setting your password, please try again."
        redirect_to :controller => '/index', :action => 'activate', :id => @act_user.id, :seq => @act_user.activation_token
      end
  
    else    
      flash[:badnotice] = 'New password and its confirmation do not match.'
      render :action => 'activate', :layout => 'login'
    end
  end

  private

  def valid_registration_domain(user, domains)
    if domains.nil? || ''.eql?(domains)
      return true
    end

    # Actually validate
    domains.split(',').each do |domain|
      if user.email.ends_with?(domain)
        return true
      end
    end
    flash[:badnotice] = 'The email address entered is not in the allowed domains for this installation. Please contact your instructor with questions.'
    return false
  end

  def showAds
    # Random selection of public courses
    @term = Term.find_current
    @publicCourses = Array.new
    unless @term.nil?
      @publicCourses = Course.find(:all, :conditions => ['term_id=? and public=?',@term.id,true], :order => 'title ASC')
      @publicCourses.shuffle
    end
    @showAds = true
  end
  
  def check_login
    return true if session[:user].nil?
    redirect_to :controller => '/home'
    return false
  end
  
  def set_title
    @title = "#{@app['title']} [CascadeLMS]"
  end
  
end
