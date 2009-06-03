class Quiz < ActiveRecord::Base
  
  belongs_to :assignment
  
  has_many :quiz_questions, :order => "position", :dependent => :destroy
  has_many :quiz_attempts, :dependent => :destroy
  
  # Clone - possibly to a different course
  def clone_questions( new_quiz_obj )
    self.quiz_questions.each do |c_question|
      # create question
      question = QuizQuestion.new
      question.quiz = new_quiz_obj
      question.position = c_question.position
      question.question = c_question.question
      question.score_question = c_question.score_question
      question.text_response = c_question.text_response
      question.multiple_choice = c_question.multiple_choice
      question.checkbox = c_question.checkbox
      new_quiz_obj.quiz_questions << question
      new_quiz_obj.save
        
      # create answers
      c_question.quiz_question_answers.each do |c_answer|          
        answer = QuizQuestionAnswer.new
        answer.position = c_answer.position
        answer.quiz_question = question
        answer.answer_text = c_answer.answer_text
        answer.correct = c_answer.correct
        question.quiz_question_answers << answer
        question.save
      end  
    end
    new_quiz_obj.save
  end
  
  def user_has_completed_attempt?( user )
    attempt = QuizAttempt.find(:first, :conditions => ["quiz_id=? and user_id=?", self.id, user.id], :order => "created_at desc" )
    return false if attempt.nil?
    return attempt.completed
  end
  
  def all_attempts_for_user( user )
    QuizAttempt.find(:all, :conditions => ["quiz_id=? and user_id=?", self.id, user.id], :order => "created_at desc" )
  end
  
  def score( quiz_attempt, user, course )
    # if it has a grade item, create a grade entry
    unless self.assignment.grade_item.nil?
      questions_to_score = 0
      self.quiz_questions.each do |question|
        questions_to_score = questions_to_score + 1 if question.score_question
      end
      
      
      correct_count = 0
      self.quiz_questions.each do |question|
      
        if question.multiple_choice
          #puts "MULTIPLE CHOICE"        
          # one correct answer
          quiz_attempt.quiz_attempt_answers.each do |answer|
            if answer.quiz_question_id == question.id 
              ## Recheck - is this answer correct
              answer.correct = answer.quiz_question_answer.correct
            end
            
            if answer.quiz_question_id == question.id and answer.correct
              #puts "CORRECT!"
              correct_count = correct_count + 1 if question.score_question
            end
          end
          
        elsif question.checkbox
          
          max_correct = 0
          question.quiz_question_answers.each do |qqa|
            max_correct = max_correct + 1 if qqa.correct && question.score_question
          end
          
          multi_correct = 0
          multi_incorrect = 0
          quiz_attempt.quiz_attempt_answers.each do |answer|
            if answer.quiz_question_id == question.id 
              ## Recheck - is this answer correct
              answer.correct = answer.quiz_question_answer.correct
            end
            
            if answer.quiz_question_id == question.id && answer.correct
              multi_correct = multi_correct + 1 if question.score_question
            elsif answer.quiz_question_id == question.id && !answer.correct
              multi_incorrect = multi_incorrect + 1 if question.score_question
            end
          end
          
          #puts "MAX CORRECT: #{max_correct}"
          #puts "MULTI_CORRECT: #{multi_correct}"
          #puts "MULTI_INCORRECT: #{multi_incorrect}"
          
          # someone forgot to select a correct answer!
          unless max_correct == 0 
            add_here = multi_correct/max_correct.to_f - multi_incorrect/max_correct.to_f            
            add_here = 0 if add_here < 0            
            #puts "ADD FOR THIS MULTI Q: #{add_here}"            
            correct_count = correct_count + add_here
          end
          
        end
      end
      
      
      # see if there is a grade entry
      entry = GradeEntry.find(:first, :conditions => ["grade_item_id=? and user_id = ? and course_id=?", self.assignment.grade_item.id, user.id, course.id]) rescue entry = GradeEntry.new
      entry = GradeEntry.new if entry.nil?
      
      entry.grade_item = self.assignment.grade_item
      entry.user = user
      entry.course = course
      #puts "POS: #{self.assignment.grade_item.points}"      
      #puts "TOSCORE: #{questions_to_score.to_f}"
      #puts "CORRECT: #{correct_count}"
      entry.points = self.assignment.grade_item.points/questions_to_score.to_f * correct_count
      #puts "POINTS: #{entry.points}"      
      entry.save 
    end   
    # end assessment of answers
  end
  
end
