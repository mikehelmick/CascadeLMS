class BlogController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    respond_to do |format|
      format.html {
        @page = params[:page].to_i
        @page = 1 if @page.nil? || @page == 0
        @post_pages = Paginator.new self, Post.count(:conditions => ["course_id = ? and published = ?", @course.id, true]), 10, @page
        @posts = Post.find(:all, :conditions => ['course_id = ? and published = ?', @course.id, true], :order => 'created_at DESC', :limit => 10, :offset => @post_pages.current.offset)

        @featured = Post.find(:all, :conditions => ['course_id = ? and published = ? and featured = ?', @course.id, true, true], :order => 'created_at DESC' )

        set_title        
      }
      format.xml { 
        @posts = Post.find(:all, :conditions => ['course_id = ? and published = ?', @course.id, true], :order => 'created_at DESC')
        render :layout => false 
      }
    end
  end
  
  def post
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @post = Post.find(params[:id]) rescue @post = nil
    if @post.nil?
      flash[:badnotice] = 'The requested blog post does not exist.'
      redirect_to :controller => '/home', :course => nil, :id => nil
      return
    end
    return unless post_in_course( @course, @post )

    unless @post.visible?
      redirect_to :controller => '/home', :course => nil, :id => nil
      return
    end
    
    @comment = Comment.new
    
    respond_to do |format|
      format.html {
        set_title()
        @breadcrumb.post = @post
        @breadcrumb.text = nil
      }
      format.xml { render :layout => false }
    end
  end
  
  # action to leave a comment
  def comment
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    return unless course_open( @course, :action => 'post', :id => params[:id] )
    @post = Post.find( params[:id] )
    return unless post_in_course( @course, @post )  
    return unless check_comments_enabled( @course, @post )    

    begin
      @comment = Comment.new(params[:comment])
      @comment.user = session[:user]
      @comment.ip = session[:ip]
      @comment.course_id = @course.id
      
      item = @post.add_comment(@comment)

      link = url_for(:controller => '/post', :action => 'view', :id => item, :course => nil, :only_path => false)
      Bj.submit "./script/runner ./jobs/comment_notify.rb #{item.id} #{@user.id} \"#{link}\""

      flash[:notice] = 'Your comment has been saved.'
      redirect_to :action => 'post', :course => @course, :id => @post
    rescue
      set_title()
      @breadcrumb.post = @post
      @breadcrumb.text = nil
      flash[:expand] = true
      render :action => 'post'
    end
  end

  def delete_comment
    return unless load_course( params[:course ] )
    post = Post.find(params[:post_id])
    return unless post_in_course( @course, post )
    return unless course_open( @course, :action => 'index' )
  
    comment = Comment.find( params[:id] )
    return false unless comment.post_id = post.id
    
    okToDelete = comment.user_id == @user.id
    unless okToDelete
      return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_blog_edit' )
    end

    return false unless post.remove_comment(comment)
    render :nothing => true
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_blog"
    @title = "Course Blog"
  end
  
  def set_title
    @title = "#{@course.title} (Course Blog)"
    @breadcrumb = Breadcrumb.for_course(@course)
    @breadcrumb.text = "Blog"
    @breadcrumb.link = url_for(:action => nil, :course => @course, :id => nil)
  end
  
  def post_in_course( course, post )
    unless course.id == post.course_id
      flash[:notice] = "You have requested an invalid blog post."
      redirect_to :controller => '/overview', :course => course
      return false
    end
    return true
  end
  
  def check_comments_enabled( course, post )  
    unless course.course_setting.blog_comments && post.enable_comments
      flash[:notice] = "Comments have been disabled for this blog post."
      redirect_to :controller => '/blog', :course => course, :id => post
      return false
    end
    return true
  end
  
  private :post_in_course, :set_title, :set_tab, :check_comments_enabled
  
end
