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
    
    flash[:notice] = "Quiz functionality is under development."
    redirect_to :controller => '/instructor/course_assignments', :action => nil, :id => params[:id], :course => params[:course]
    return if true
    
    ## setup some basics 
    @assignment = Assignment.new
    @assignment.default_dates
    @quiz = Quiz.new
    @quiz.attempt_maximum = -1
    
    @categories = GradeCategory.for_course( @course )
    
    @title = "New Quiz - #{@course.title}"
    
    @new_quiz = true
  end
  
  def create
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    
    @points = params[:point_value]
    
    ## actually create the assignment, make it a quiz, and setup the quiz
    @assignment = Assignment.new( params[:assignment] )
    @assignment.course = @course
    @assignment.grade_category_id = params[:grade_category_id].to_i
    @assignment.make_quiz
    
    @quiz = Quiz.new( params[:quiz] )
    @quiz.assignment = @assignment
    @quiz.linear_score = !@quiz.survey && (@points.nil? || (@points.class.to_s.eql?('String') && @points.eql?('')))
    @assignment.quiz = @quiz
    
    @gradeItem = nil
    if !@quiz.survey && !@points.nil? && @points.to_i > 0
      @gradeItem = GradeItem.new
      @gradeItem.name = @assignment.title
      @gradeItem.date = @assignment.due_date.to_date
      @gradeItem.points = @points.to_f
      @gradeItem.display_type = "s"
      @gradeItem.visible = false
      @gradeItem.grade_category_id = @assignment.grade_category_id
      @gradeItem.assignment_id = @assignment.id
      @gradeItem.course_id = @course.id
    end
    
    success = true
    begin
      Assignment.transaction do 
        success = @assignment.save
        raise 'error' unless success
        success = @quiz.save
        raise 'error' unless success
        success = @gradeItem.save unless @gradeItem.nil?
        raise 'error' unless success
        
        flash[:notice] = "Quiz '#{@assignment.title}' has been created successfully."
      end  
      
    rescue Exception => doh
      flash[:badnotice] = 'There was an error creating the quiz.'
      success = false
    end
    
    
    ## if everything is successful --- go to quiz listing
    if success
      redirect_to :controller => '/instructor/quiz', :action => 'questions', :course => @course, :quiz => @assignment.id
      
    else
      @categories = GradeCategory.for_course( @course )
      render :action => 'new'
    end
    
  end
  
  def questions
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:quiz] )
    return unless assignment_in_course( @course, @assignment )
    
    
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
