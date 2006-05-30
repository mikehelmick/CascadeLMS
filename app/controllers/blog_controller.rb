class BlogController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @page = @params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @post_pages = Paginator.new self, Post.count(:conditions => ["course_id = ? and published = ?", @course.id, true]), 10, @page
    @posts = Post.find(:all, :conditions => ['course_id = ? and published = ?', @course.id, true], :order => 'created_at DESC', :limit => 10, :offset => @post_pages.current.offset)
    
    @featured = Post.find(:all, :conditions => ['course_id = ? and published = ? and featured = ?', @course.id, true, true], :order => 'created_at DESC' )
    
    set_title
  end
  
  def post
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @post = Post.find(params[:id])
    return unless post_in_course( @course, @post )  
    
    @comment = Comment.new  
  end
  
  # action to leave a comment
  def comment
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    @post = Post.find( params[:id] )
    return unless post_in_course( @course, @post )  
    return unless check_comments_enabled( @course, @post )    
    
    @comment = Comment.new(params[:comment])
    @comment.user = session[:user]
    @comment.post = @post
    @comment.ip = 'unknown'  # FIX THIS
    
    if @comment.save
      flash[:highlight] = "comment_#{@comment.id}"
      flash[:notice] = 'Your comment has been saved'
      redirect_to :action => 'post', :course => @course, :id => @post
    else
      flash[:expand] = true
      render :action => 'post'
    end
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_blog"
    @title = "Course Blog"
  end
  
  def set_title
    @title = "#{@course.title} (Course Blog)"
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
