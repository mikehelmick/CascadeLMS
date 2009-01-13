# Controller for the creation and maintenance of quizzes
class Instructor::QuizController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  verify :method => :post, :only => [ :delete_question ],
         :redirect_to => { :action => :questions }
  
  def index
    flash[:notice] = "The quiz listing is shown with the assignment listing."
    redirect_to :controller => '/instructor/course_assignments', :action => nil, :id => params[:id], :course => params[:course]
  end
  
  def new
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    
    #flash[:notice] = "Quiz functionality is under development."
    #redirect_to :controller => '/instructor/course_assignments', :action => nil, :id => params[:id], :course => params[:course]
    #return if true
    
    ## setup some basics 
    @assignment = Assignment.new
    @assignment.default_dates
    @quiz = Quiz.new
    @quiz.attempt_maximum = -1
    @quiz.anonymous = true
    
    @categories = GradeCategory.for_course( @course )
    
    @title = "New Quiz - #{@course.title}"
    
    @new_quiz = true
  end
  
  def create
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    
    @points = params['point_value']
    
    ## actually create the assignment, make it a quiz, and setup the quiz
    @assignment = Assignment.new( params[:assignment] )
    @assignment.course = @course
    @assignment.grade_category_id = params[:grade_category_id].to_i
    @assignment.make_quiz
    
    @quiz = Quiz.new( params[:quiz] )
    @quiz.assignment = @assignment
    @quiz.anonymous = false if !@quiz.survey
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
      @gradeItem.course_id = @course.id
    end
    
    success = true
    begin
      Assignment.transaction do 
        success = @assignment.save
        raise 'error' unless success
        success = @quiz.save
        raise 'error' unless success
        @gradeItem.assignment = @assignment unless @gradeItem.nil?
        success = @gradeItem.save unless @gradeItem.nil?
        raise 'error' unless success
        
        ## See if we should automatically generate the quiz
        unless params[:generate_survey].nil?
          @quiz.entry_exit = true
          @course.ordered_outcomes.each do |outcome|
            # create question
            question = QuizQuestion.new
            question.quiz = @quiz
            question.question = "I am able to: \"#{outcome.outcome}\""
            question.text_response = false
            question.multiple_choice = true
            question.checkbox = false
            @quiz.quiz_questions << question
            @quiz.save
            
            # create answers
            responses = ["Strongly Agree", "Agree", "Indifferent", "Disagree", "Strongly Disagree", "N/A" ]
            responses.each do |response|
              answer = QuizQuestionAnswer.new
              answer.quiz_question = question
              answer.answer_text = response
              question.quiz_question_answers << answer
              question.save
            end  
          end
          
          # save everything down
          @quiz.save
        end
        
        flash[:notice] = "Quiz '#{@assignment.title}' has been created successfully."
      end  
      sucess = true
    rescue Exception => doh
      @new_quiz = true
      flash[:badnotice] = 'There was an error creating the quiz.'
      success = false
    end
    
    
    ## if everything is successful --- go to quiz listing
    if success
      redirect_to :controller => '/instructor/quiz', :action => 'questions', :course => @course, :id => @assignment.id
      
    else
      @categories = GradeCategory.for_course( @course )
      render :action => 'new'
    end
    
  end
  
  def edit
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    @quiz = @assignment.quiz
    @categories = GradeCategory.for_course( @course )
    
    @title = "Edit Quiz - #{@assignment.title}"
  end
  
  def update
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    
    Quiz.transaction do 
      @assignment.update_attributes( params[:assignment] )
      @assignment.quiz.update_attributes( params[:quiz] ) 
      
      flash[:notice] = "Quiz '#{@assignment.title}' has been updated."
      redirect_to :controller => '/instructor/quiz', :action => 'questions', :course => @course, :id => @assignment.id
      return
    end
  
    flash[:badnotice] = "There was an error updating this quiz."
    redirect_to :action => 'questions', :course => @course, :id => @assignment
  end
  
  def questions
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    @quiz = @assignment.quiz
  end
  
  def new_question
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    @quiz_question = QuizQuestion.new
    create_blank_answers
  end
  
  def create_question
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    @quiz = @assignment.quiz
    QuizQuestion.transaction do
      # build question
      @quiz_question = QuizQuestion.new( params[:quiz_question])
      @quiz_question.text_response = params[:question_type].eql?('text_response')
      @quiz_question.multiple_choice = params[:question_type].eql?('multiple_choice')
      @quiz_question.checkbox = params[:question_type].eql?('checkbox')
      @quiz_question.quiz = @quiz
      @quiz.quiz_questions << @quiz_question
      @quiz.save
      
      # build answers
      answers = build_answers( params, @quiz_question )
      answers.each { |i| @quiz_question.quiz_question_answers << i }
      @quiz_question.save
      
      unless @quiz.survey
        correct_count = 0
        answers.each { |i| correct_count = correct_count + 1 if i.correct }
        
        if correct_count != 1 && @quiz_question.multiple_choice 
          flash[:badnotice] = 'For a multiple choice question type, there must be only exactly 1 correct answer.'
          render :action => 'new_question'
          return
        elsif correct_count == 0 && @quiz_question.checkbox
          flash[:badnotice] = 'There must be at least one correct answer for this question type.'
          render :action => 'new_question'
          return
        end
        
      end
      
    end
    
    redirect_to :action => 'questions', :course => @course, :id => @assignment    
  end
  
  def edit_question
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    @quiz_question = nil
    @assignment.quiz.quiz_questions.each do |question|
      @quiz_question = question if question.id == params[:question].to_i
    end
    
    if @quiz_question.nil?
      flash[:badnotice] = "The requested question could not be found."
      redirect_to :action => 'questions', :course => @course, :id => @assignment
      return
    end
    
    create_blank_answers()
    answers = @quiz_question.quiz_question_answers
    @answer_1 = answers[0] unless answers[0].nil?
    @answer_2 = answers[1] unless answers[1].nil?
    @answer_3 = answers[2] unless answers[2].nil?
    @answer_4 = answers[3] unless answers[3].nil?
    @answer_5 = answers[4] unless answers[4].nil?
    @answer_6 = answers[5] unless answers[5].nil?
    @answer_7 = answers[6] unless answers[6].nil?
    @answer_8 = answers[7] unless answers[7].nil?
    @answer_9 = answers[8] unless answers[8].nil?
    @answer_10 = answers[9] unless answers[9].nil?
  end
  
  def update_question
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    @quiz_question = nil
    @assignment.quiz.quiz_questions.each do |question|
      @quiz_question = question if question.id == params[:question].to_i
    end
    
    if @quiz_question.nil?
      flash[:badnotice] = "The requested question could not be found."
      redirect_to :action => 'questions', :course => @course, :id => @assignment
      return
    end
    
    QuizQuestion.transaction do
      @quiz_question.update_attributes( params[:quiz_question] )
      
      answers = @quiz_question.quiz_question_answers
      1.upto(10) do |i|       
        if params["answer_#{i}"]['answer_text'].eql?('')
          # if the answer text is blank
          if !answers[i-1].nil?
            # and there is a question at that spot...
            answers[i-1].destroy
            answers[i-1] = nil
          end
        else  
          if answers[i-1].nil?
            # nothing did exist at this point
            answer = QuizQuestionAnswer.new( params["answer_#{i}"] )
            answer.position = answers.length + 1
            answer.quiz_question = @quiz_question
            answer.save
            answers[i-1] = answer
          else
            # something did exist
            answers[i-1].answer_text = params["answer_#{i}"]['answer_text']
            answers[i-1].save
          end
        end
      end
      
      pos = 1
      answers.compact!
      answers.each do |ans|
        ans.position = pos
        ans.save
        pos = pos.next
      end

      flash[:notice] = "Question was successfully updated."
      redirect_to :action => 'questions', :course => @course, :id => @assignment
      return
    end
      
      
    flash[:badnotice] = "There was an error updating this question."
    redirect_to :action => 'edit_question', :course => @course, :id => @assignment, :question => @question
    return
  end
  
  def reorder
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    @quiz = @assignment.quiz
  end
  
  def sort
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    # get the outcomes at this level
    Quiz.transaction do
      @assignment.quiz.quiz_questions.each do |question|
        question.position = params['question-order'].index( question.id.to_s ) + 1
        question.save
      end
    end
    
    render :nothing => true
  end
  
  def reorder_answers
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    @question = nil
    @assignment.quiz.quiz_questions.each do |question|
      @question = question if question.id == params[:question].to_i
    end
    
    if @question.nil?
      flash[:badnotice] = "The requested question could not be found."
      redirect_to :action => 'questions', :course => @course, :id => @assignment
      return
    end
    
  end
  
  def sort_answers
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    @question = nil
    @assignment.quiz.quiz_questions.each do |question|
      @question = question if question.id == params[:question].to_i
    end
    
    unless @question.nil?
      # get the outcomes at this level
      QuizQuestion.transaction do
        @question.quiz_question_answers.each do |answer|
          answer.position = params['answer-order'].index( answer.id.to_s ) + 1
          answer.save
        end
      end
    end
    
    render :nothing => true
  end
  
  def delete_question
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_course_assignments' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:id] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    
    @question = nil
    @assignment.quiz.quiz_questions.each do |question|
      @question = question if question.id == params[:question].to_i
    end
    
    if @question.nil?
      flash[:badnotice] = "The requested question could not be found."
    else  
      if @question.destroy
        flash[:notice] = "The requested question was deleted successfully."
      else
        flash[:badnotice] = "There was an error deleted the question."
      end
    end
    
    redirect_to :action => 'questions', :course => @course, :id => @assignment
  end
  
  private
  
  def create_blank_answers
    @answer_1 = QuizQuestionAnswer.new
    @answer_2 = QuizQuestionAnswer.new
    @answer_3 = QuizQuestionAnswer.new
    @answer_4 = QuizQuestionAnswer.new
    @answer_5 = QuizQuestionAnswer.new
    @answer_6 = QuizQuestionAnswer.new
    @answer_7 = QuizQuestionAnswer.new
    @answer_8 = QuizQuestionAnswer.new
    @answer_9 = QuizQuestionAnswer.new
    @answer_10 = QuizQuestionAnswer.new
  end
  
  def build_answers( params, question )
    answers = Array.new
    
    1.upto(10) do |i|
      unless params["answer_#{i}"]['answer_text'].eql?('')
        answer = QuizQuestionAnswer.new( params["answer_#{i}"] )
        answer.position = answers.length + 1
        answer.quiz_question = question
        
        answers << answer
      end
    end

    # in case the question creation failes...
    @answer_1 = answers[0] 
    @answer_1 = QuizQuestionAnswer.new if @answer_1.nil?
    @answer_2 = answers[1]  
    @answer_2 = QuizQuestionAnswer.new if @answer_2.nil?
    @answer_3 = answers[2]  
    @answer_3 = QuizQuestionAnswer.new if @answer_3.nil?
    @answer_4 = answers[3]  
    @answer_4 = QuizQuestionAnswer.new if @answer_4.nil?
    @answer_5 = answers[4]  
    @answer_5 = QuizQuestionAnswer.new if @answer_5.nil?
    @answer_6 = answers[5]  
    @answer_6 = QuizQuestionAnswer.new if @answer_6.nil?
    @answer_7 = answers[6]  
    @answer_7 = QuizQuestionAnswer.new if @answer_7.nil?
    @answer_8 = answers[7]  
    @answer_8 = QuizQuestionAnswer.new if @answer_8.nil?
    @answer_9 = answers[8]  
    @answer_9 = QuizQuestionAnswer.new if @answer_9.nil?
    @answer_10 = answers[9]  
    @answer_10 = QuizQuestionAnswer.new if @answer_10.nil?

    
    return answers 
  end
  
  def set_tab
     @show_course_tabs = true
     @tab = "course_instructor"
  end

  def set_title
     @title = "Quiz - #{@course.title}"
  end
  
end
