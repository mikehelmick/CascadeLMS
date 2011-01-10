class Instructor::SharingController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  verify :method => :post, :only => [ :add_share ],
         :redirect_to => { :action => :index }
  
  def index
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    @title = "Sharing : #{@course.title}"
  end
  
  def add_share
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    newUser = User.find(params['add_user'])
    unless newUser.instructor? || newUser.admin?
      flash[:badnotice] = "Selected user is not an instructor or administrator."
    else
      if @course.share_with_user(newUser)
        flash[:notice] = "Selected user has been added. You can now set the sharing properties for this user."
      else
        flash[:badnotice] = "There was an error saving the sharing settings."
      end
    end
    
    redirect_to :action => 'index', :add_user => nil, :course => @course
  end
  
  def del_share
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    share = CourseShare.find(:first, :conditions => ["course_id = ? and user_id = ?", @course.id, params[:id]])
    share.destroy unless share.nil?
    
    render :nothing => true
  end
  
  def update_sharing
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    shareMap = Hash.new
    CourseShare.transaction do
      # Sharing is always reset
      shares = CourseShare.find(:all, :conditions => ["course_id = ?", @course])
      shares.each do |share|
        share.assignments = params["u_#{share.user_id}_a"].eql?("true")
        share.documents = params["u_#{share.user_id}_d"].eql?("true")
        share.blogs = params["u_#{share.user_id}_b"].eql?("true")
        share.outcomes = params["u_#{share.user_id}_o"].eql?("true")
        share.rubrics = params["u_#{share.user_id}_r"].eql?("true")
        share.wiki = params["u_#{share.user_id}_w"].eql?("true")
        
        share.save
      end
    end
    
    flash[:notice] = "Sharing settings have been updated."
    redirect_to :action => 'index'
  end
  
  def search
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_users' )
    
    st = params[:searchterms].downcase
    if st.length >= 4
      sv = "%#{st}%"
      @users = User.find(:all, :conditions => ["(LOWER(uniqueid) like ? or LOWER(first_name) like ? or LOWER(last_name) like ? or LOWER(preferred_name) like ?) and (instructor = ? or admin = ?)", sv, sv, sv, sv, true, true], :order => "uniqueid asc")
    else
      @invalid = true
    end
  
    render :layout => false
  end
  
end
