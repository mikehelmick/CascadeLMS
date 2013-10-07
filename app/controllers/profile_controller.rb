class ProfileController < ApplicationController
  before_filter :ensure_logged_in

  def index
    redirect_to :controller => '/home', :action => nil, :id => nil, :course => nil
  end

  def view
    load_profile(params)

    profilename = @user_profile.user.display_name rescue @user.display_name
    @title = "Profile for #{profilename}"
    @breadcrumb = Breadcrumb.new
    @breadcrumb.text = "Profile for #{profilename}"
    unless @user_profile.user_id.nil?
      @breadcrumb.link = url_for(:controller => '/profile', :action => 'view', :id => @user_profile.user_id)
    end

    @show_following = false
    if !@user_profile.user.id.eql?(@user.id)
      if @notificationCount > 0 && Notification.mark_following_notification_read(@user, @user_profile.user)
        @notificationCount = @user.notification_count
      end

      @show_following = true
      @feed_subscription = @user_profile.user.create_feed.get_subscription(@user) 
    else
      @followers = Array.new
      @user.feed.feed_subscriptions.each do |fs|
        @followers << fs.user unless fs.user.nil?
      end
    end
    @view_mode = true
  end

  def posts
    load_profile(params)

    profilename = @user_profile.user.display_name rescue @user.display_name
    @title = "Posts for #{profilename}"
    @breadcrumb = Breadcrumb.new
    @breadcrumb.text = "Posts by #{profilename}"
    unless @user_profile.user_id.nil?
      @breadcrumb.link = url_for(:controller => '/profile', :action => 'posts', :id => @user_profile.user_id)
    end
    @view_mode = false

    # Find posts that have been shared w/ the viewing user either explicitly, or because they were shared with a course the user
    # is in.
    # select * from items 
    #   left outer join item_shares on items.id = item_shares.item_id 
    #   where items.user_id=3 and 
    #     (item_shares.user_id=1 || 
    #     item_shares.course_id in (select course_id from courses_users where user_id=1 and course_student=1 or course_instructor=1 or course_guest=1 or course_assistant=1));
    
    joins = ["left outer join item_shares on items.id = item_shares.item_id"]
    conditions = ["items.user_id = ? and (item_shares.user_id = ? || item_shares.course_id in (select course_id from courses_users where user_id=? and course_student=1 or course_instructor=1 or course_guest=1 or course_assistant=1))", @user_profile.user.id, @user.id, @user.id]
    
    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @pages = Paginator.new(self, Item.count(:joins => joins, :conditions => conditions), 25, @page)
    @items = Item.find(:all, :joins => joins, :conditions => conditions, :order => 'created_at DESC, item_id DESC', :limit => 25, :offset => @pages.current.offset)
    @items = Item.apply_acls(@items, @user)

    # Throws pagination off a bit, but removes duplicates (following, in 1 or more courses w/ user)
    ids = Hash.new
    @items =
        @items.select do |item|
          keep = !ids[item.id]
          ids[item.id] = true
          keep
        end
  end

  def follow
    load_profile(params)

    @show_following = false
    if !@user_profile.user.id.eql?(@user.id)
      @show_following = true
      @feed_subscription = @user_profile.user.feed.get_subscription(@user)
      if @feed_subscription.nil?
        @user_profile.user.feed.subscribe_user(@user)
        @feed_subscription = @user_profile.user.feed.get_subscription(@user)

        # See if we've previously notified on this user.
        notification = Notification.find(:first, :conditions => ["user_id = ? and followed_by_user_id = ?", @user_profile.user.id, @user.id], :order => 'created_at desc')
        # Find 1 day ago - only notify if we haven't done so in the last 24 hours.
        time = Time.now - 60*60*24
        if notification.nil? || notification.created_at < time
          message = "#{@user.display_name} followed you."
          link = url_for(:controller => '/profile', :action => 'view', :id => @user.id, :only_path => false)
          notification = Notification.create_followed(@user_profile.user, message, link, @user)
          notification.save
        end
      else
        @feed_subscription.destroy
        @feed_subscription = nil
      end
    end
    render :layout => false
  end

  def edit
    @user_profile = @user.user_profile
    @user_profile = UserProfile.new if @user_profile.nil?
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

  def status
    # Create the item
    item = Item.new
    item.user = @user
    item.body = params[:status]

    # Find individual users to publish to.
    feed_subscriptions = 
        if params[:followers]
          @user.feed.feed_subscriptions
        else
          Array.new
        end  

    public_post = true
    # Find the courses to publish to.
    courses = Array.new
    @user.courses_in_term( @term ).each do |cu|
      if params["c#{cu.course_id}"]
        courses << cu.course
        # If the poster is an instructor in all courses that this is scoped to, then it
        # is allowed to be a public post, otherwise it is not
        public_post = public_post && (cu.course_instructor || cu.course_assistant)          
      end
    end
    item.public = false;

    begin
      Item.transaction do
        item.save

        courses.each do |course|
          item.share_with_course(course, item.created_at)
        end

        feed_subscriptions.each do |fs|
          item.share_with_user(fs.user, item.created_at)
        end
        # Seems silly - but share with yourself to ensure visibility
        item.share_with_user(@user, item.created_at)
      end
      flash[:notice] = 'Your update has been shared.'
    rescue RuntimeError => re
      logger.error("Error posting update: #{re.inspect}")
      flash[:badnotice] = 'There was an error saving your update.'
    end

    feed = Feed.find(params[:feed]) rescue feed = nil?
    if feed.nil? || !feed.user.nil?
      # Error, or shared from home, redirec to home.
      redirect_to :controller => '/home', :action => nil, :id => nil
    else
      # Redirect to the course stream that this was shared from.
      redirect_to :controller => '/overview', :course => feed.course_id, :action => nil, :id => nil
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
