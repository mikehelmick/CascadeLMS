require 'oauth'
require 'twitter'

class Instructor::TwitterController < Instructor::InstructorBase
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    if @course.course_twitter.nil? || !@course.course_twitter.auth_success
      redirect_to :action => 'setup'
    else
      # display the last few tweets
      oauth = Twitter::OAuth.new(@app['oauth_consumer_key'], @app['oauth_consumer_secret'])
      courseTwitter = @course.course_twitter
      oauth.authorize_from_access(courseTwitter.access_token, courseTwitter.access_secret)
      twitter = Twitter::Base.new(oauth)
      
      @credentials = twitter.verify_credentials
      
      @timeline = twitter.user_timeline(courseTwitter.twitter_id)
    end
  end
  
  def disable
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    if !@course.course_twitter.nil?
      @course.course_twitter.destroy
    end
    
    flash[:notice] = 'Twitter has been disabled for this course. You can set it up again at any time.'
    redirect_to :action => 'setup'
  end
  
  def setup
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    if @course.course_twitter.nil?
      courseTwitter = CourseTwitter.new
      courseTwitter.course = @course  

      # setup oauth with twitter
      puts "key: #{@app['oauth_consumer_key']}"
      puts "secret: #{@app['oauth_consumer_secret']}"
      
      oauth = Twitter::OAuth.new(@app['oauth_consumer_key'], @app['oauth_consumer_secret'])
      ## write info
      courseTwitter.request_token = oauth.request_token.token
      courseTwitter.request_secret = oauth.request_token.secret
      courseTwitter.auth_url = oauth.request_token.authorize_url
      courseTwitter.save

      @course.course_twitter = courseTwitter
    end
  
    if @course.course_twitter.auth_success
      redirect_to :action => 'index'
    else
      @courseTwitter = @course.course_twitter
    end    
  end
  
  def authorize
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    if @course.course_twitter.nil?
      redirect_to :action => 'setup'
    else
      @courseTwitter = @course.course_twitter
      @courseTwitter.auth_code = params['auth_code']
      # authorize this pin
      oauth = Twitter::OAuth.new(@app['oauth_consumer_key'], @app['oauth_consumer_secret'])
      
      access_token, access_secret = oauth.authorize_from_request(@course.course_twitter.request_token, @course.course_twitter.request_secret, @course.course_twitter.auth_code)
      @courseTwitter.access_token = access_token
      @courseTwitter.access_secret = access_secret
      @courseTwitter.auth_success = true
      @courseTwitter.twitter_enabled = true
      
      twitter = Twitter::Base.new(oauth)      
      @credentials = twitter.verify_credentials
      @courseTwitter.twitter_name = @credentials['screen_name']
      @courseTwitter.twitter_id = @credentials['id']
      @courseTwitter.save
      
      
      flash[:notice] = "This course now has twitter integration"
      redirect_to :action => 'index'
    end  
  end
  
  private
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
    @title = "Twitter Integration"
  end
  
end
