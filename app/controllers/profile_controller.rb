class ProfileController < ApplicationController
  before_filter :ensure_logged_in

  def index
    redirect_to :controller => '/home', :action => nil, :id => nil, :course => nil
  end

  def view
    if !params[:id].nil? && !''.eql?(params[:id])
      begin
        profile_user = User.find(params[:id])        
        @user_profile = profile_user.user_profile
        if @user_profile.nil?
          @user_profile = UserProfile.new
          @user_profile.user = profile_user
        end
      rescue
        flash[:badnotice] = 'The requested profile could not be found'
      end
    else
      @user_profile = @user.user_profile if @user_profile.nil?
      @user_profile = UserProfile.new if @user_profile.nil?
    end
puts "Profile #{@user_profile}"

    profilename = @user_profile.user.display_name rescue @user.display_name
    @title = "Profile for #{profilename}"
    @breadcrumb = Breadcrumb.new
    @breadcrumb.text = "Profile for #{profilename}"
    unless @user_profile.user_id.nil?
      @breadcrumb.link = url_for(:controller => '/profile', :action => 'view', :id => @user_profile.user_id)
    end
  end

  def edit
    @user_profile = @user.user_profile
    puts "Profile: #{@user_profile}"
    @user_profile = Profile.new if @user_profile.nil?
    setup_edit()
  end

  def update
    @user_profile = @user.user_profile
    success = false
    if @user_profile.nil?
      @user_profile = UserProfile.new(params[:user_profile])
      @user_profile.user_id = @user.id
      success = @user_profile.save
    else 
      success = @user_profile.update_attributes(params[:user_profile])
    end
    
    if success
      flash[:notice] = 'Your profile has been updated.'
      redirect_to :controller => '/profile', :action => 'view'
    else
      flash[:badnotice] = 'There was an error saving your profile.'
      setup_edit()
      render :action => 'edit'
    end
  end

  private
  def setup_edit()
    # prepare for autocomplete
    load_majors()

    @title = 'Edit Your Profile'
    @breadcrumb = Breadcrumb.new
    @breadcrumb.text = 'Edit'
    @breadcrumb.link = url_for(:controller => '/profile', :action => 'edit')
  end
end
