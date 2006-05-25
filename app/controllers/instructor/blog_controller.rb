class Instructor::BlogController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    return false unless list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_blog_post' )
    
    set_title
    
    @page = @params[:page].to_i
    @page = 1 if @page.nil? || @page == 0
    @post_pages = Paginator.new self, Post.count(:conditions => ["course_id = ?", @course.id]), 20, @page
    @posts = Post.find(:all, :conditions => ['course_id = ?', @course.id], :order => 'created_at DESC', :limit => 20, :offset => @post_pages.current.offset)
  
    true
  end

  def new
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_blog_post' )
    
    
    @post = Post.new
  end

  def create
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_blog_post' )
    
    
    @post = Post.new(params[:post])
    @post.course = @course
    @post.user = session[:user]
    if @post.save
      flash[:notice] = 'Post was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_blog_post' )
    
    @post = Post.find(params[:id])
  end

  def update
    @post = Post.find(params[:id])
    if @post.update_attributes(params[:post])
      flash[:notice] = 'Post was successfully updated.'
      flash[:highlight] = @post.id
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_blog_post' )
    
    Post.find(params[:id]).destroy
    
    render :nothing => true
  end
  
  def delete_comment
    return unless load_course( params[:course ] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_blog_edit' )
    post = Post.find(params[:post])
    return unless post_in_course( @course, post )
  
    comment = Comment.find( params[:id] )
    return false unless comment.post_id = post.id
      
    return false unless comment.destroy
  
    render :nothing => true
  end
  
  def set_tab
    @show_course_tabs = true
    @tab = "course_instructor"
  end
  
  def set_title
    @title = "Course Blog - #{@course.title}"
  end
  
  def post_in_course( course, post )
    unless course.id == post.course_id
      flash[:notice] = "You have requested an invalid blog post."
      redirect_to :controller => '/overview', :course => course
      return false
    end
    return true
  end
  
  private :set_tab, :set_title, :post_in_course
  
end
