class Instructor::ResultsController < Instructor::InstructorBase
  
  before_filter :ensure_logged_in
  before_filter :set_tab

  layout 'noright'
  
  def compare
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_survey_results' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    
    @surveys = Quiz.find(:all, :conditions => ["course_id = ? and entry_exit = ?", @course, true], :order => "id asc")

    @all_answer_count_maps = Hash.new
    @all_question_answer_totals = Hash.new
    @all_text_responses = Hash.new

    @surveys.each do |survey|
       @all_answer_count_maps[survey.id], @all_question_answer_totals[survey.id], @all_text_responses[survey.id] =
            aggregate_survey_responses( survey )
    end
    
    quest_arrays = Array.new
    @surveys.each { |sur| quest_arrays << sur.quiz_questions }
    same_length = true
    quest_arrays.each { |arr| same_length = same_length && quest_arrays[0].length==arr.length}
    
    flash[:badnotice] = "The entry/exit surveys are not identical, comparisons are unreliable." if (!same_length)
    # more extensive validation...

    @breadcrumb = Breadcrumb.for_course(@course, true)
    @breadcrumb.outcomes = true
    @breadcrumb.text = 'Entry/Exit Surveys'
  end

  def quiz_summary
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_survey_results' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    @quiz = @assignment.quiz
    
    if @assignment.quiz.survey 
      redirect_to :action => 'survey', :course => @course, :assignment => @assignment
    end
        
    # map students to 2 columns
    @students = @course.students
    size = @students.length / 2
    @column1 = Array.new
    0.upto(size) { |i| @column1 << @students[i] }
    @column2 = Array.new
    (size+1).upto(@students.length-1) { |i| @column2 << @students[i] }
      
    # find the correct attempt for each student
    @quiz_attempts = Array.new
    @students.each do |student|
      quiz_attempt = QuizAttempt.find(:first, :conditions => ["quiz_id=? and user_id=?",@quiz.id,student.id], :order => "created_at desc")  
      @quiz_attempts << quiz_attempt unless quiz_attempt.nil?
    end  
      
    # need to do complicated aggregation here
    # we can make some assumptions since 
    @answer_count_map = Hash.new
    @question_answer_total = Hash.new
    @text_responses = Hash.new
    
    @quiz.quiz_questions.each do |question|
       
      if question.text_response
        @text_responses[question.id] = Array.new
        responses = QuizAttemptAnswer.find(:all,:conditions => ["quiz_question_id = ? and quiz_attempt_id in (?)", question.id, @quiz_attempts.collect(&:id)])
        responses.each do |response|
          @text_responses[question.id] << response.text_answer
        end
      
      else
        total_responses = 0
        question.quiz_question_answers.each do |answer|
          responses  = QuizAttemptAnswer.count(:conditions => ["quiz_question_answer_id = ? and quiz_attempt_id in (?)", answer.id, @quiz_attempts.collect(&:id)])
          @answer_count_map[answer.id] = responses
          total_responses = total_responses + responses
        end
        @question_answer_total[question.id] = total_responses
        
      end
    end
         
  end


  def survey_export
    survey_results_common( params )
    
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = "inline; filename=survey_results_#{@assignment.id}.csv"
    
    render :layout => false
  end
  
  def quiz_export
    internal_quiz_summary( params )
    
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = "inline; filename=quiz_results_#{@assignment.id}.csv"
    
    render :layout => false
  end

  def survey
    survey_results_common( params )
    @title = "Survey Results - #{@assignment.title}"

    @breadcrumb = Breadcrumb.for_course(@course, true)
    @breadcrumb.assignment = @assignment
    @breadcrumb.text = 'Survey Resuls'
  end
  
  def survey_question
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_survey_results' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    @quiz = @assignment.quiz
    
    if @quiz.anonymous 
      flash[:badnotice] = "This is an anonymous survey, expanded results are not available."
      redirect_to :action => 'survey', :course => @course, :assignment => @assignment
    end
    
    if ( ! @assignment.quiz.survey ) 
      redirect_to :action => 'quiz', :course => @course, :assignment => @assignment
    end
    
    # load question
    @question = QuizQuestion.find(:first, :conditions => ["id =? and quiz_id = ?", params[:id].to_i, @quiz.id] )
    if @question.nil?
      flash[:badnotice] = "The selected question could not be found."
      return redirect_to( :action => 'survey', :course => @course, :assignment => @assignment )
    end
    
    
    @students = @course.students   
    
    # load student answers
    @student_response = Hash.new
    @students.each do |user|
      @student_response[user.id] = Hash.new
      
      attempt = QuizAttempt.find(:first, :conditions => ["quiz_id = ? and user_id = ?", @assignment.quiz.id, user.id])
      unless attempt.nil?
        answers = QuizAttemptAnswer.find(:all, :conditions => ["quiz_attempt_id = ? and quiz_question_id = ?", attempt.id, @question.id])
        
        if @question.text_response
          if answers.length > 0
            @student_response[user.id][@question.id] = answers[0].text_answer 
          end
        else
          answers.each do |answer|
            @student_response[user.id][answer.quiz_question_answer_id] = true
          end
        end
      end
    end
    
    
  end

  def quiz
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_quiz_results' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    @quiz = @assignment.quiz
    
    if ( @assignment.quiz.survey ) 
      redirect_to :action => 'survey', :course => @course, :id => @assignment
    end    
    
    @has_text_responses = false
    @quiz.quiz_questions.each { |question| @has_text_responses = @has_text_responses || question.text_response }
    
    if @assignment.grade_item
      # load student grades
      @grades = Hash.new
      entries = GradeEntry.find(:all, :conditions => ["grade_item_id=?", @assignment.grade_item.id ] )
      entries.each do |e|
        @grades[e.user_id] = e.points
      end
    end
    
    @attempts = Hash.new
    all_attempts = @quiz.quiz_attempts.sort { |a,b| a.created_at <=> b.created_at } 
    all_attempts.each do |attempt|
      @attempts[attempt.user_id] = attempt
    end

    @title = "Results for #{@quiz.assignment.title}"
    @breadcrumb = Breadcrumb.for_course(@course, true)
    @breadcrumb.assignment = @assignment
    @breadcrumb.text = 'Quiz Submissions'
  end
  
  def for_student
    return unless load_course( params[:course] )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    @quiz = @assignment.quiz
    
    if @quiz.anonymous 
      flash[:badnotice] = "This is an anonymous survey, expanded results are not available."
      redirect_to :action => 'survey', :course => @course, :assignment => @assignment
    end
    
    if @quiz.survey
      return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_survey_results' )
    else
      return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_quiz_results' )
    end
    
    # make sure the student exists
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'quiz', :course => @course, :assignment => @assignment, :id => nil
    end
    
    unless @assignment.grade_item.nil?
      @grade_entry = GradeEntry.find(:first, :conditions => ["grade_item_id=? and user_id=?", @assignment.grade_item.id, @student.id ] )
      @grade_entry = GradeEntry.new if @grade_entry.nil?
    end

    # load any existing rubric entries
    @rubric_entry_map = @quiz.assignment.rubric_map_for_user(@student.id)
        
    @attempt = QuizAttempt.find(:first, :conditions => ["quiz_id = ? and user_id = ?", @quiz.id, @student.id], :order => "created_at desc")    
    @answer_map = map_existing_quiz_attempt( @attempt ) unless @attempt.nil?
    @answer_map = Hash.new if @answer_map.nil?  
      
    @questions = @quiz.quiz_questions  
    @title = "Results for #{@student.display_name} - '#{@assignment.title}'"
    @breadcrumb = Breadcrumb.for_course(@course, true)
    @breadcrumb.assignment = @assignment
    @breadcrumb.text = "Quiz Resuls for #{@student.display_name}"
  end
  
  def remove_attempt
    return unless load_course( params[:course] )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    @quiz = @assignment.quiz
    
    if @quiz.anonymous 
      flash[:badnotice] = "This is an anonymous survey, expanded results are not available."
      redirect_to :action => 'survey', :course => @course, :assignment => @assignment
    end
    
    if @quiz.survey
      return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_survey_results' )
    else
      return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_quiz_results' )
    end
    
    # make sure the student exists
    @student = User.find(params[:id])
    if ! @student.student_in_course?( @course.id )
      flash[:badnotice] = "Invalid student record requested."
      redirect_to :action => 'quiz', :course => @course, :assignment => @assignment, :id => nil
    end
    
    unless @assignment.grade_item.nil?
      @grade_entry = GradeEntry.find(:first, :conditions => ["grade_item_id=? and user_id=?", @assignment.grade_item.id, @student.id ] )
      @grade_entry = GradeEntry.new if @grade_entry.nil?
    end
        
    @attempt = QuizAttempt.find(:first, :conditions => ["quiz_id = ? and user_id = ?", @quiz.id, @student.id], :order => "created_at desc")    
    
    unless @attempt.nil? 
      @attempt.destroy
      flash[:notice] = "Attempt removed, the student may now retake the quiz."
    end
    
    redirect_to :action => 'for_student', :course => @course, :assignment => @assignment, :id => @student
  end
  
  def rescore
    return unless load_course( params[:course] )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    @quiz = @assignment.quiz
    
    if @quiz.survey
      flash[:notice] = "You can no rescore a survey."
      redirect_to :action => 'survey', :course => @course, :assignment => @assignment
    end
    
    Quiz.transaction do
      # for each student
      @course.students.each do |student|
        # find the most recent submission for the student
        quiz_attempt = QuizAttempt.find(:first, :conditions => ["quiz_id=? and user_id=?", @quiz.id, student.id], :order => "created_at desc" )
        if quiz_attempt.nil?
                  
          # no quiz attempt for this student, update, or create grade_item to zero
          unless @assignment.grade_item.nil?
            grade_entry = GradeEntry.find(:first, :conditions => ["grade_item_id=? and user_id=?", @assignment.grade_item.id, student.id])
            grade_entry = GradeEntry.new if grade_entry.nil?
            grade_entry.user = student
            grade_entry.course = @course
            grade_entry.grade_item = @assignment.grade_item
            grade_entry.points = 0
            grade_entry.save
          end
          
        else
          # regrade quiz attempt          
          @quiz.score( quiz_attempt, student, @course )

        end

      end
    end
    
    flash[:notice] = "All scores have been recalculated."
    redirect_to :controller => 'instructor/results', :action => 'quiz', :course => @course, :assignment => @assignment
  end


private

  def map_existing_quiz_attempt( quiz_attempt )
    # not first attempt - but also not complete...
    # build the answer set 
    @answer_map = Hash.new
    
    attemptAnswers = QuizAttemptAnswer.find(:all, :conditions => ["quiz_attempt_id = ?", quiz_attempt.id])
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
     @show_course_tabs = true
     @tab = "course_instructor"
  end

  def set_title
     @title = "Quiz - #{@course.title}"
  end
  
  def internal_quiz_summary(params)
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_survey_results' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    @quiz = @assignment.quiz
    
    @students = @course.students
    
    @answer_count_map = Hash.new
    @question_answer_total = Hash.new
    @student_answer_map = Hash.new
    
    # For each student, process latest attempt
    @students.each do |student|
      @student_answer_map[student.id] = Hash.new
      attempt = QuizAttempt.find(:first, :conditions => ["quiz_id = ? and user_id = ? and completed = ?", @quiz.id, student.id, true], :order => "created_at desc" )      
      
      unless attempt.nil?
        attempt.quiz_attempt_answers.each do |qaa|
          if qaa.quiz_question_answer_id.nil?
            ## text question
            @student_answer_map[student.id][qaa.quiz_question_id] = qaa.text_answer
          else
            ## multiple choice
            @answer_count_map[qaa.quiz_question_answer_id] = 0 if @answer_count_map[qaa.quiz_question_answer_id].nil?
            @question_answer_total[qaa.quiz_question_id] = 0 if @question_answer_total[qaa.quiz_question_id].nil?
            
            @answer_count_map[qaa.quiz_question_answer_id] = @answer_count_map[qaa.quiz_question_answer_id].next
            @question_answer_total[qaa.quiz_question_id] = @question_answer_total[qaa.quiz_question_id].next
            
            @student_answer_map[student.id][qaa.quiz_question_id] = Hash.new if @student_answer_map[student.id][qaa.quiz_question_id].nil?
            @student_answer_map[student.id][qaa.quiz_question_id][qaa.quiz_question_answer_id] = 1
          end
        end
      end
      
    end
    
  end
  
  def survey_results_common( params )
    return unless load_course( params[:course] )
    return unless ensure_course_instructor_or_ta_with_setting( @course, @user, 'ta_view_survey_results' )
    return unless quiz_enabled( @course )
    return unless course_open( @course, :action => 'index' )
    return unless load_assignment( params[:assignment] )
    return unless assignment_in_course( @course, @assignment )
    return unless assignment_is_quiz( @assignment )
    @quiz = @assignment.quiz
    
    if ( !@assignment.quiz.survey ) 
      redirect_to :action => 'quiz', :course => @course, :assignment => @assignment
    end
    
    # map students to 2 columns
    @students = @course.students
    size = @students.length / 2
    @column1 = Array.new
    0.upto(size) { |i| @column1 << @students[i] }
    @column2 = Array.new
    (size+1).upto(@students.length-1) { |i| @column2 << @students[i] }
      
    # if anonymous, run through all attempts
    @student_map = Hash.new
    if @quiz.anonymous
      attempts = QuizAttempt.find(:all, :conditions => ["quiz_id = ?", @quiz.id])
      attempts.each { |attempt| @student_map[attempt.user_id] = true }  
    end  
    
    aggregate_survey_responses( @quiz )
  end
  

end
