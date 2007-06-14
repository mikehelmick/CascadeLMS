# Controller for the creation and maintenance of quizzes
class Instructor::QuizController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  def index
    flash[:notice] = "The quiz listing is shown with the assignment listing."
    redirect_to :controller => '/instructor/course_assignments', :action => nil, :id => params[:id], :course => params[:course]
  end
  
  def new
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    
    ## setup some basics 
    @assignment = Assignment.new
    @journal_field = JournalField.new
    @categories = GradeCategory.for_course( @course )
    
    @attempts = -1
        
    @title = "New Quiz - #{@course.title}"
  end
  
  def create
    
  end
  
  
  private
  def quiz_enabled( course )
    unless course.course_setting.enable_quizzes
      flash[:badnotice] = "Quizzes are not enabled for this course."
      redirect_to :controller => '/instructor/index', :course => course
      return false
    end
    return true
  end
  
  def set_tab
     @show_course_tabs = true
     @tab = "course_instructor"
  end

  def set_title
     @title = "Quiz - #{@course.title}"
  end
  
end
