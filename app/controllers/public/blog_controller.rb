class Public::BlogController < ApplicationController

  before_filter :set_tab
  before_filter :load_user_if_logged_in
  
  def index
    return unless load_course( params[:course] )
    return unless course_is_public( @course )
    
    @page = params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @post_pages = Paginator.new self, Post.count(:conditions => ["course_id = ? and published = ?", @course.id, true]), 10, @page
    @posts = Post.find(:all, :conditions => ['course_id = ? and published = ?', @course.id, true], :order => 'created_at DESC', :limit => 10, :offset => @post_pages.current.offset)
    
    @featured = Post.find(:all, :conditions => ['course_id = ? and published = ? and featured = ?', @course.id, true, true], :order => 'created_at DESC' )
    
    set_title
    get_breadcrumb().text = 'Blog'
  end
  
  def post
    return unless load_course( params[:course] )
    return unless course_is_public( @course )
    
    @post = Post.find(params[:id])
    return unless post_in_course(@course, @post)

    @title = @post.title
    get_breadcrumb().post = @post
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_blog"
    @title = "Course Blog"
  end
  
  def set_title
    @title = "#{@course.title} (Course Blog - Public Access)"
  end
  
  def post_in_course( course, post )
    unless course.id == post.course_id
      flash[:notice] = "You have requested an invalid blog post."
      redirect_to :controller => '/public/overview', :course => course
      return false
    end
    return true
  end

  def get_breadcrumb()
    @breadcrumb = Breadcrumb.for_course(@course)
    @breadcrumb.public_access = true
    return @breadcrumb
  end
  
  private :post_in_course, :set_title, :set_tab, :get_breadcrumb
  
end
