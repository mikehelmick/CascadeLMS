class ForumsController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  layout 'application'
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @topics = ForumTopic.find(:all, :conditions => ["course_id =?", @course.id], :order => "position asc")
    
    set_title
    init_breadcrumb('Forums')
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

  def reorder
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topics = ForumTopic.find(:all, :conditions => ["course_id =?", @course.id], :order => "position asc")
    
    set_title('Reorder')
    init_breadcrumb('Forums')
  end

  def sort_topics
    return unless load_course( params[:course] )
    return unless ensure_course_instructor( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topics = ForumTopic.find(:all, :conditions => ["course_id =?", @course.id], :order => "position asc")

    # get the outcomes at this level
    ForumTopic.transaction do
      @topics.each do |topic|
        topic.position = params['topic-order'].index( topic.id.to_s ) + 1
        topic.save
      end
    end
    
    render :nothing => true
  end
  
  def new_post
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topic = ForumTopic.find(params[:topic])
    return unless topic_in_course( @course, @topic )
    return unless topic_open( @course, @topic )
    
    @post = ForumPost.new
    set_title
    init_breadcrumb()
    @breadcrumb.forum = @topic    
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
          @next = ForumPost.find(@next.id, :lock => true)
          
          @next.replies = @post.replies - 1
          @next.parent_post = 0
          @next.last_user_id = @user.id
          @next.save

          @item = @post.item
          unless @item.nil?
            fake_item = @next.create_item()
            # Copy applicable items over
            @item.body = fake_item.body
            @item.user_id = @next.user_id
            @item.forum_post_id = @next.id
            @item.created_at = fake_item.created_at
            @item.save
 
            # Adjust stream ordering
            FeedsItems.update_all("timestamp = \"#{@item.created_at.to_formatted_s(:db)}\"", "item_id = #{@item.id}")
          end
          
          ForumPost.update_all("parent_post = #{@next.id}", "parent_post = #{@post.id}")
        
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
          # Only post, destroy the item
          @item = @post.item
          @item.destroy unless @item.nil?
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
        @topic = ForumTopic.find(@parent.forum_topic_id, :lock => true)
        @parent = ForumPost.find(params[:parent], :lock => true)
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

      unless @user.id == @post.user_id || @user.instructor_in_course?( @course.id ) || @user.assistant_in_course_with_privilege?( @course.id, 'ta_course_blog_edit')
        flash[:badnotice] = "You don't have permission to edit this post."
        redirect_for_post( @post )
        return
      end

      @post.update_attributes( params[:post] )   
      @post.post = "#{@post.post} \n <br/><i>Post edited by #{@user.display_name} at #{Time.now.to_formatted_s(:long)}</i>"
          
      if @post.save
        if @post.parent_post == 0
          item = @post.item
          unless item.nil?
            item.body = @post.post
            item.save
          end
        end
        
        flash[:notice] = "Your post has been edited."
        redirect_for_post( @post )
      else
        render :action => 'edit'
      end

    else
      @post = ForumPost.new( params[:post] )
      @post.forum_topic = @topic
      @post.parent_post = 0
      @post.user = @user
      @parent = nil

      if !params[:parent].nil? && !params[:parent].eql?('')
        @post.parent_post = params[:parent].to_i
        @parent = ForumPost.find( params[:parent].to_i )
        @parent.replies = @parent.replies + 1 rescue @parent.replies = 1
        @parent.last_user_id = @user.id
      end 
    
      success = false
      ForumPost.transaction do
        @topic.post_count = @topic.post_count + 1
        @topic.change_time
        @topic.user = @user
        success = @topic.save
        success = @post.save && success
        @post.publish()
        success = @parent.save && success unless @parent.nil?
      end
      
      if success
        flash[:notice] = 'New post created in this forum.'

        link = ""
        if ( @post.parent_post == 0 ) 
          link = url_for(:controller => '/forums', :action => 'read', :id => @post.id, :course => @course, :only_path => false)
        else
          link = url_for(:controller => '/forums', :action => 'read', :id => @post.parent_post, :course => @course, :only_path => false)
        end
        reply_parent =
          if @post.parent_post == 0
            @post.id
          else
            @post.parent_post
          end

        # If this is a reply, we should notify the original author and other posters.
        unless @parent.nil?
          item = @parent.item
          unless item.nil?
            notification_link = url_for(:controller => '/post', :action => 'view', :id => item, :course => nil, :only_path => false)
            Bj.submit "./script/runner ./jobs/comment_notify.rb #{item.id} #{@user.id} \"#{notification_link}\""
          end
        end
          
        reply_link = url_for(:controller => '/forums', :action => 'reply', :id => @post.id, :parent => reply_parent, :course => @course, :only_path => false)
        unwatch_link = url_for(:controller => 'forums', :action => 'stop_watch', :id => @topic.id, :course => @course, :only_path => false)
        Bj.submit "./script/runner ./jobs/forum_topic_notifier.rb #{@topic.id} #{@post.id} \"#{link}\" \"#{reply_link}\" \"#{unwatch_link}\""
        redirect_for_post(@post)
      else
        init_breadcrumb('Forums')
        flash[:badnotice] = 'Failed to save forum post.'
        render :action => 'new_post' 
      end
    end
  end
  
  def new_forum
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    unless @course.course_setting.enable_forum_topic_create
      return unless ensure_course_instructor_or_assistant( @course, @user )
    end
    return unless course_open( @course, :action => 'index' )
    
    @topic = ForumTopic.new
    init_breadcrumb('Forums')
  end
  
  def post_report
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_assistant( @course, @user )
    
    @count_map = Hash.new
    @course.courses_users.each do |u|
      @count_map[u.user.id] = 0
    end
    
    @topics = ForumTopic.find(:all, :conditions => ["course_id = ?", @course.id] )
    @topics.each do |topic|
      @posts = ForumPost.find(:all, :conditions => ["forum_topic_id = ?", topic.id] )
      
      @posts.each do |post|
        @count_map[post.user_id] = @count_map[post.user_id].next rescue @count_map[post.user_id] = 0
      end
    end
        
    @title = "Forum Post Report for #{@course.title}"
    init_breadcrumb("Forums")
  end
  
  def create_forum
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_assistant( @course, @user )
    return unless course_open( @course, :action => 'index' )
    
    @topic = ForumTopic.new(params[:topic])
    @topic.course = @course
    @topic.user = session[:user]
    @topic.post_count = 0
    @topic.change_time
    @course.forum_topics << @topic
    
    if @course.save
      flash[:notice] = 'New forum topic created.'
      redirect_to :action => 'index'
    else
      render :action => 'new_forum'
    end   
  end
  
  def watch
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @topic = ForumTopic.find(params[:id])
    return unless topic_in_course( @course, @topic )
    
    watch = ForumWatch.find(:first, :conditions => ["user_id=? and forum_topic_id=?", @user.id, @topic.id])
    if watch.nil?
      watch = ForumWatch.new
      watch.user_id = @user.id
      watch.forum_topic_id = @topic.id
      watch.save
    end
    
    flash[:notice] = "You are now watching the forum '#{@topic.topic}', and you will get an email when there are new posts."
    redirect_to :action => 'view_topic', :course => @course, :id => @topic
  end
  
  def stop_watch
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @topic = ForumTopic.find(params[:id])
    return unless topic_in_course( @course, @topic )
 
    ForumWatch.delete_all(["user_id=? and forum_topic_id=?", @user.id, @topic.id])
    
    flash[:notice] = "You no longer watching the forum '#{@topic.topic}'."
    redirect_to :action => 'view_topic', :course => @course, :id => @topic    
  end
  
  def view_topic
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @topic = ForumTopic.find(params[:id])
    return unless topic_in_course( @course, @topic )
  
    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @post_pages = Paginator.new self, ForumPost.count(:conditions => ["forum_topic_id = ? and parent_post = ?", @topic.id, 0]), 25, @page
    @posts = ForumPost.find(:all, :conditions => ["forum_topic_id = ? and parent_post = ?", @topic.id, 0 ], :order => 'updated_at DESC', :limit => 25, :offset => @post_pages.current.offset)

    init_breadcrumb()
    @breadcrumb.forum = @topic
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
    
    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @post_pages = Paginator.new self, ForumPost.count(:conditions => ["forum_topic_id = ? and parent_post = ?", @topic.id, @parent_post.id]), 50, @page
    @posts = ForumPost.find(:all, :conditions => ["forum_topic_id = ? and parent_post = ?", @topic.id, @parent_post.id ], :order => 'created_at ASC', :limit => 50, :offset => @post_pages.current.offset)
    
    @title = @parent_post.headline

    init_breadcrumb()
    @breadcrumb.forum = @topic
    @breadcrumb.text = h @parent_post.headline
  end
  
  def edit
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @post = ForumPost.find(params[:id])
    @topic = @post.forum_topic
    return unless topic_in_course( @course, @topic )
    return unless topic_open( @course, @topic )
    
    @parent = params[:parent]
    
    if @user.instructor_in_course?( @course.id ) || @user.assistant_in_course_with_privilege?( @course.id, 'ta_course_blog_edit')
      if @user.id != @post.user_id
        flash[:notice] = "You are editing some else's post as a instrcutor or TA.  Any edit you make will be appended to the end of the post with your name on it."
      end     
    end

    init_breadcrumb()
    @breadcrumb.forum = @topic
    @breadcrumb.text = 'Edit Post'
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
    @post.post = "[quote]_posted by #{@reply_to.user.display_name} at #{@reply_to.created_at.to_formatted_s(:short)}_ \n\n #{@reply_to.post}\n[/quote]"
    
    init_breadcrumb()
    @breadcrumb.forum = @topic
    @breadcrumb.text = 'Reply'
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
  
  def set_title(extra = nil)
    if extra.nil?
      @title = "#{@course.title} (Course Forum)"
    else
      @title = "#{extra} #{@course.title} (Forums)"
    end
  end

  def init_breadcrumb(extra_text = nil)
    @breadcrumb = Breadcrumb.for_course(@course)
    @breadcrumb.text = extra_text unless extra_text.nil?
  end
  
  def redirect_for_post( post )
    if ( post.parent_post == 0 )
        redirect_to :action => 'read', :id => post.id
    else
        redirect_to :action => 'read', :id => post.parent_post
    end
  end
  
  
end
