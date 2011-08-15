class QuizController < ApplicationController
  
  before_filter :ensure_logged_in
  before_filter :set_tab
  
  layout 'quiz'
  
  verify :method => :post, :only => [ :take ],
         :redirect_to => { :controller => '/home', :course => nil, :action => nil, :id => nil }

  def index
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )

    redirect_to :controller => '/assignments', :course => @course
  end
  
  def start
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_is_quiz( @assignment )
    return unless quiz_open( @assignment )
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    @quiz = @assignment.quiz
    
    load_quiz_dependencies()
    
    set_title
  end
  
  def attempt_info
    @quiz_attempt = QuizAttempt.find( params[:id] )
    @quiz = @quiz_attempt.quiz
    @assignment = @quiz.assignment
    @extension = @assignment.extension_for_user( @user )
    render :partial => 'timings', :layout => false
  end
  
  def take
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_is_quiz( @assignment )
    return unless quiz_open( @assignment )
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    @quiz = @assignment.quiz    
    
    @quiz_attempt = QuizAttempt.find( params[:qa] )
    return unless attempt_for_user_and_quiz( @quiz_attempt, @user, @quiz )
    
    # perform the save
    save_quiz_answers( params )
    
    if @quiz_attempt.completed
      flash[:notice] = "Your answers have been saved."
      redirect_to :action => 'results', :course => @course, :id => @assignment
      return
    else  # this was an intermediary save
      flash[:notice] = "All previous work has been saved.  You can continue taking the quiz, including chaning previous answer."
      load_quiz_dependencies
    end
    
    render :action => 'start'
  end
  
  def results
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_is_quiz( @assignment )
    return unless quiz_available( @assignment )
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    @quiz = @assignment.quiz
    
    if @quiz.survey
      flash[:notice] = "Your survey answers have been saved, thank you."
      return redirect_to :controller => '/assignments', :course => @course
    end
    
    load_quiz_dependencies( true )
    
    if !@quiz_attempt.completed
      flash[:badnotice] = "You cannot view the results for this quiz, becuase your most recent attempt hasn't been completed."
      redirect_to :action => 'start', :course => @course, :id => @assignment
      return
    end 
    
    if @assignment.released && @assignment.grade_item
      @grade_item = GradeItem.find( :first, :conditions => ['assignment_id = ?', @assignment.id] )
      @grade_entry = GradeEntry.find(:first, :conditions => ["grade_item_id=? and user_id=?", @assignment.grade_item.id, @user.id ] )
      @grade_entry = GradeEntry.new if @grade_entry.nil?
      @feedback_html = @grade_entry.comment.to_html rescue @feedback_html = ''

      # load any existing rubric entries
      if @assignment.rubrics.size > 0
         @rubric_entry_map = @assignment.rubric_map_for_user(@user.id, false)
      end
    end   
    
    @title = "Quiz Results"
    @show_course_tabs = true
    @tab = "course_assignments"
    render :layout => 'application'
  end
  
  def abort
    return unless load_course( params[:course] )
    return unless allowed_to_see_course( @course, @user )
    
    @assignment = Assignment.find(params[:id]) rescue @assignment = Assignment.new
    return unless assignment_in_course( @assignment, @course )
    return unless assignment_is_quiz( @assignment )
    return unless quiz_open( @assignment )
    return unless assignment_available_for_students_team( @course, @assignment, @user.id )
    @quiz = @assignment.quiz
    
    @attempts = @quiz.all_attempts_for_user( @user )
    if @attempts.length == 0 || @attempts[0].completed
      flash[:badnotice] = "You don't have an incomplete quiz attempt for the quiz #{@assignment.title}, so I can't abort the attempt."
      redirect_to :controller => 'assignments', :course => @course, :id => nil
    end
    
    # else  - first entry is incomplete
    QuizAttempt.transaction do 
      @attempts[0].destroy
      @quiz.score( @attempts[1], @user, @course )
    end
    
    flash[:notice] = "Quiz attempt aborted - here is your current attempt."
    redirect_to :action => 'results', :course => @course, :id => @assignment
  end
  
  
  private
  

  
  def save_quiz_answers( params )
    QuizAttempt.transaction do
      @quiz_attempt.save_count = @quiz_attempt.save_count + 1
      
      @answer_map = map_existing_quiz_attempt
      
      # cycle through questions to determine the right params
      @quiz.quiz_questions.each do |question|
        
        if question.text_response
          answer = QuizAttemptAnswer.new
          answer = @answer_map[question.id] unless @answer_map[question.id].nil?
          
          answer.quiz_question = question
          answer.quiz_attempt = @quiz_attempt
          answer.text_answer = params["answer_#{question.id}"]  
          answer.save
        
        elsif question.multiple_choice
          answer = QuizAttemptAnswer.new
          answer = @answer_map[question.id] unless @answer_map[question.id].nil?
          
          # find the quiz question answer
          quizQA = QuizQuestionAnswer.find( params["answer_#{question.id}"]) rescue quizQA = nil
          
          if quizQA.nil?
            answer.destroy
          else
            answer.quiz_question = question
            answer.quiz_attempt = @quiz_attempt
            answer.quiz_question_answer = quizQA
            answer.correct = quizQA.correct
            answer.save
          end
          
        elsif question.checkbox
          answers = Array.new
          answers = @answer_map[question.id] unless @answer_map[question.id].nil?
          answers.each { |i| i.destroy }
          
          question.quiz_question_answers.each do |potentialAnswer|
            unless params["answer_#{question.id}_#{potentialAnswer.id}"].nil?
              answer = QuizAttemptAnswer.new
              answer.quiz_question = question
              answer.quiz_attempt = @quiz_attempt
              answer.quiz_question_answer = potentialAnswer
              answer.correct = potentialAnswer.correct
              answer.save
            end
          
          end
          
        end
        
      end
      
      if ! params['commit'].index('Save Answers - Complete').nil?
        @quiz_attempt.completed = true
      end
      @quiz_attempt.save
      @quiz.score( @quiz_attempt, @user, @course )
    end    
  end
  
  def load_quiz_dependencies( load_for_results = false )
    
    ## initialization is different based on if it is a quiz or a survey
    if @quiz.survey
      # Since this is a survey - a user can modify their answers until they have completed
      @quiz_attempt = QuizAttempt.find(:first, :conditions => ["quiz_id = ? and user_id = ?", @quiz.id, @user.id], :order => "created_at asc")
      if !@quiz_attempt.nil? && @quiz_attempt.completed
        # since this survey has been completed, we can't let the user try again, sorry
        flash[:badnotice] = 'You have already completed the selected survey.  If you feel that there has been an error, please contact your instructor.'
        redirect_to :controller => '/assignments', :course => @course
        return
        
      elsif @quiz_attempt.nil?  
        map_new_quiz_attempt
      else
        map_existing_quiz_attempt
      end
    
    else
      # this is a quiz
      @allAttempts = QuizAttempt.find(:all, :conditions => ["quiz_id = ? and user_id = ?", @quiz.id, @user.id], :order => "created_at desc")
      
      if @quiz.attempt_maximum > 0
        if @allAttempts.length >= @quiz.attempt_maximum && @allAttempts[0].completed
          flash[:badnotice] = 'You have used all of your attempts on this quiz.'
          if !load_for_results
            redirect_to :controller => '/assignments', :course => @course
            return
          end
        elsif @allAttempts.length == 0  
          flash[:notice] = "This is your first attempt at this quiz.  You may attempt it #{@quiz.attempt_maximum} times."
        elsif @allAttempts.length < @quiz.attempt_maximum && ! @allAttempts[0].completed  
          flash[:notice] = "This is attempt #{@allAttempts.length} out of a possible #{@quiz.attempt_maximum}."            
        elsif @allAttempts.length < @quiz.attempt_maximum && @allAttempts[0].completed 
          if load_for_results
            flash[:notice] = "You can still attempt this quiz #{@quiz.attempt_maximum - @allAttempts.length} times."
          else
            flash[:notice] = "This is attempt #{@allAttempts.length + 1} out of a possible #{@quiz.attempt_maximum}."     
          end     
        end
      else  
        flash[:notice] = "This quiz offeres unlimited retries."
      end
      
      if @allAttempts.length == 0
        @quiz_attempt = nil
      else
        @quiz_attempt = @allAttempts[0]
        @quiz_attempt = nil if @quiz_attempt.completed && !load_for_results
      end
      
      if @quiz_attempt.nil?  
        map_new_quiz_attempt
      else
        map_existing_quiz_attempt
      end
      
    
    end
    
    # take care of randomization
    @questions = @quiz.quiz_questions
    if @quiz.random_questions
      master_list = @questions
      @questions = Array.new
      
      # shuffle the questions
      while( master_list.length > 0 )
        idx = rand(master_list.length)
        @questions << master_list[idx]
        master_list.delete_at(idx)
      end
    end
    
    ## Upgrade quiz DS on disk
    @questions.each do |question|
      question.save if question.question_html.nil?
      question.quiz_question_answers.each do |ans|
        ans.save if ans.answer_text_html.nil?
      end
    end
    
  end
  
  def map_new_quiz_attempt
    # first attempt - we actually want to record this in the database
    @quiz_attempt = QuizAttempt.new
    @quiz_attempt.quiz = @quiz
    @quiz_attempt.user = @user
    @quiz_attempt.completed = false
    @quiz_attempt.save_count = 0
    @quiz_attempt.save
    
    # build the answer set
    @answer_map = Hash.new
    @quiz.quiz_questions.each do |question|
      if question.checkbox
        @answer_map[question.id] = Array.new
      else
        thisAns = QuizAttemptAnswer.new
        thisAns.quiz_attempt = @quiz_attempt
        thisAns.quiz_question = question
        @answer_map[question.id] = thisAns
      end
    end
  end
  
  def map_existing_quiz_attempt
    # not first attempt - but also not complete...
    # build the answer set 
    @answer_map = Hash.new
    
    attemptAnswers = QuizAttemptAnswer.find(:all, :conditions => ["quiz_attempt_id = ?", @quiz_attempt.id])
    attemptAnswers.each do |attempt|
      # if it is a checkbox question - there might be multiple answers
      if attempt.quiz_question.checkbox
        @answer_map[attempt.quiz_question.id] = Array.new if @answer_map[attempt.quiz_question.id].nil?
        @answer_map[attempt.quiz_question.id] << attempt
      else
        @answer_map[attempt.quiz_question.id] = attempt
      end
    end
    
    return @answer_map
  end
  
  def set_tab
    @show_course_tabs = false
    @tab = ""
    @title = " - QUIZ -"
  end
  
  def set_title
    if @quiz.survey 
      @title = "Survey: #{@assignment.title}"
    else
      @title = "Quiz: #{@assignment.title}"
    end
  end
  
  def quiz_available( assignment )
    if @assignment.upcoming?
      flash[:badnotice] = "Selected quiz is not available at this time."
      redirect_to :controller => '/assignments', :course => @course
      return false
    end
    return true
  end
  
  def quiz_open( assignment )
    # check extension - we won't check open date if extension is allowd
    @extension = assignment.extension_for_user( @user )
    if @extension.nil? || (@extension.nil? && !extension.past?)
      unless assignment.current?
        flash[:badnotice] = "Selected quiz is not available at this time."
        redirect_to :controller => '/assignments', :course => @course
        return false
      end
    end
    return true
  end
  
  def assignment_is_quiz( assignment )
    unless assignment.is_quiz?
      flash[:badnotice] = "Invalid quiz selected."
      redirect_to :controller => '/assignments', :course => @course
      return false      
    end
    return true
  end
  
  def attempt_for_user_and_quiz( quiz_attempt, user, quiz )
    unless quiz_attempt.user_id == user.id && quiz_attempt.quiz_id == quiz.id
      flash[:badnotice] = "Invalid quiz/course/user combination."
      redirect_to :controller => '/assignments', :course => @course
      return false     
    end
    return true
  end
  
end
