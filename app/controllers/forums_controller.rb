class ForumsController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  layout 'noright'
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @topics = ForumTopic.find(:all, :conditions => ["course_id =?", @course.id], :order => "position asc")
    
    set_title
  end
  
  def toggle_open
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topic = ForumTopic.find(params[:id])
    return unless topic_in_course( @course, @topic )
    
    @topic.allow_posts = ! @topic.allow_posts
    if @topic.save
      set_highlight "topic_#{@topic.id}"
      flash[:notice] = "Forum status changed."
      redirect_to :action => 'index'
    else
      flash[:badnotice] = "Error changing forum status."
      redirect_to :action => 'index'
    end
    
  end
  
  def move_up
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topic = ForumTopic.find(params[:id])
    return unless topic_in_course( @course, @topic )
    
    (@course.forum_topics.to_a.find {|s| s.id == @topic.id}).move_higher
    set_highlight "topic_#{@topic.id}"
    redirect_to :action => 'index'
  end
  
  def move_down
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topic = ForumTopic.find(params[:id])
    return unless topic_in_course( @course, @topic )
    
    (@course.forum_topics.to_a.find {|s| s.id == @topic.id}).move_lower
    set_highlight "topic_#{@topic.id}"
    redirect_to :action => 'index'    
  end
  
  def new_post
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topic = ForumTopic.find(params[:topic])
    return unless topic_in_course( @course, @topic )
    return unless topic_open( @course, @topic )
    
    @post = ForumPost.new
  end
  
  def delete
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    
    @post = ForumPost.find(params[:id])
    @parent = @post if @post.id == params[:parent].to_i
    @parent = ForumPost.find(params[:parent]) if @parent.nil?
    @topic = @parent.forum_topic
    return unless topic_in_course( @course, @topic )
    
    if @parent.id == @post.id
      # delete root
      @next = ForumPost.find(:first, :conditions => ["parent_post = ?", @parent.id], :order => "created_at asc" )
      
      unless @next.nil?
        success = false
        ForumPost.transaction do 
          @next.replies = @post.replies - 1
          @next.parent_post = 0
          @next.last_user_id = @user.id
          @next.save
          
          ForumPost.update_all( "parent_post = #{@next.id}","parent_post = #{@post.id}" )
        
          @topic.post_count = @topic.post_count - 1
          @topic.user = @user
          @topic.save
          
          @post.destroy
       
          success = true
        end
        
        if success
          flash[:notice] = "Post deleted - second post has been promoted to the topic leader."
        else
          flash[:notice] = "There was an error deleting the selected post."
        end
        redirect_to :action => 'read', :id => @next.id
        
      else
        # there is no next
        success = false
        ForumPost.transaction do
          @post.destroy
          @topic.post_count = @topic.post_count - 1
          @topic.user = @user
          @topic.save
          success = true
        end
        
        if success
          flash[:notice] = "Post deleted.   Since it was the only post, the entire topic has been removed."
          redirect_to :action => 'view_topic', :id => @topic
        else
          flash[:notice] = "Error deleting post."
          redirect_to :action => 'read', :id => @post
        end
      end
      
    else
      
      success = false
      ForumPost.transaction do
        @post.destroy
        
        @topic.post_count = @topic.post_count - 1
        @topic.user = @user
        @topic.save
        
        @parent.replies = @parent.replies - 1
        @parent.last_user_id = @user.id
        @parent.save
        
        success = true
      end
      
      if success
        flash[:notice] = "Post deleted."
        redirect_to :action => 'read', :id => @parent
      else
        flash[:notice] = "Error deleting post."
        redirect_to :action => 'read', :id => @parent
      end
      
    end
    
  end
  
  def submit_post
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topic = ForumTopic.find(params[:topic])
    return unless topic_in_course( @course, @topic )
    return unless topic_open( @course, @topic )
    
    if ( params[:id] ) 
      @post = ForumPost.find( params[:id] )
      @post.update_attributes( params[:post] ) 
      
      if @post.save
        flash[:notice] = "Your post has been edited."
        
         if ( @post.parent_post == 0 )
            redirect_to :action => 'read', :id => @post.id
         else
            redirect_to :action => 'read', :id => @post.parent_post
         end
        
      else
        render :action => 'edit'
      end
      
    else
      @post = ForumPost.new( params[:post] )
      @post.forum_topic = @topic
      @post.parent_post = 0
      @post.user = @user
      
      puts "parent #{params[:parent]}"
      
      if !params[:parent].nil? && !params[:parent].eql?('')
        @post.parent_post = params[:parent].to_i
        @parent = ForumPost.find( params[:parent].to_i )
        @parent.replies = @parent.replies + 1 rescue @parent.replies = 1
        @parent.last_user_id = @user.id
      end
  
    
      success = false
      ForumPost.transaction do
        @topic.post_count = @topic.post_count + 1
        @topic.user = @user
        success = @topic.save
        success = @post.save && success
        success = @parent.save && success unless @parent.nil?
      end
      
      if success
        flash[:notice] = 'New post created in this forum.'
        if ( @post.parent_post == 0 )
            redirect_to :action => 'read', :id => @post.id
         else
            redirect_to :action => 'read', :id => @post.parent_post
         end
      else
        render :action => 'new_post' 
      end
      
    end
  end
  
  def new_forum
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topic = ForumTopic.new
  end
  
  def create_forum
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topic = ForumTopic.new(params[:topic])
    @topic.course = @course
    @topic.user = session[:user]
    @topic.post_count = 0
    @course.forum_topics << @topic
    
    if @course.save
      flash[:notice] = 'New forum topic created.'
      redirect_to :action => 'index'
    else
      render :action => 'new_forum'
    end   
  end
  
  def view_topic
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @topic = ForumTopic.find(params[:id])
    return unless topic_in_course( @course, @topic )
  
    @page = @params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @post_pages = Paginator.new self, ForumPost.count(:conditions => ["forum_topic_id = ? and parent_post = ?", @topic.id, 0]), 25, @page
    @posts = ForumPost.find(:all, :conditions => ["forum_topic_id = ? and parent_post = ?", @topic.id, 0 ], :order => 'updated_at DESC', :limit => 25, :offset => @post_pages.current.offset)
  end
  
  def read
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    begin
      @parent_post = ForumPost.find(params[:id])
      @topic = @parent_post.forum_topic
      return unless topic_in_course( @course, @topic )
    rescue
      flash[:notice] = 'Invalid forum requested.'
      redirect_to :controller => "/forums", :course => @course
      return
    end
    
    @page = @params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @post_pages = Paginator.new self, ForumPost.count(:conditions => ["forum_topic_id = ? and parent_post = ?", @topic.id, @parent_post.id]), 15, @page
    @posts = ForumPost.find(:all, :conditions => ["forum_topic_id = ? and parent_post = ?", @topic.id, @parent_post.id ], :order => 'created_at ASC', :limit => 15, :offset => @post_pages.current.offset)
    
    @title = @parent_post.headline
  end
  
  def edit
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @post = ForumPost.find(params[:id])
    @topic = @post.forum_topic
    return unless topic_in_course( @course, @topic )
    return unless topic_open( @course, @topic )
    
    puts (Time.now - @post.created_at).to_i
    if (Time.now - @post.created_at).to_i > 900
      flash[:notice] = "This post was created more than 15 minutes ago, and can no longer be edited."
      redirect_to :action => 'read', :id => params[:parent]
    end
  end
  
  def reply
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @reply_to = ForumPost.find(params[:id])
    @parent = @reply_to if @reply_to.id == params[:parent].to_i
    @parent = ForumPost.find(params[:parent]) if @parent.nil?
    @topic = @parent.forum_topic
    return unless topic_in_course( @course, @topic )
    return unless topic_open( @course, @topic )
    
    @post = ForumPost.new
    @post.headline = "RE: #{@reply_to.headline}"
    @post.post = "<div class=\"quote\">_posted by #{@reply_to.user.display_name} at #{@reply_to.created_at.to_formatted_s(:short)}_ \n\n #{@reply_to.post}\n</quote>"
  end
  
  private
  
  def topic_open( course, topic )
    unless topic.allow_posts
      flash[:notice] = "The selected forum topic is closed to new posts."
      redirect_to :controller => '/forums', :course => @course
      return false
    end
    return true
  end
  
  def topic_in_course( course, topic )
    unless course.id == topic.course_id
      flash[:notice] = "You have requested an invalid forum topic."
      redirect_to :controller => '/overview', :course => course
      return false
    end
    return true
  end
  
  def post_in_topic( post, topic ) 
    unless post.forum_topic_id == topic.id
      flash[:notice] = "You have requested an invalid post."
      redirect_to :controller => '/forums', :course => @course
      return false
    end
    return true
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_forum"
    @title = "Course Forum"
  end
  
  def set_title
    @title = "#{@course.title} (Course Forum)"
  end
  
  
end
