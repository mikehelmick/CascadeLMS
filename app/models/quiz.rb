class Quiz < ActiveRecord::Base
  
  belongs_to :assignment
  
  has_many :quiz_questions, :order => "position", :dependent => :destroy
  has_many :quiz_attempts, :dependent => :destroy
  
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
      
      correct_count = 0
      self.quiz_questions.each do |question|
      
        if question.multiple_choice
          # one correct answer
          quiz_attempt.quiz_attempt_answers.each do |answer|
            if answer.quiz_question_id == question.id && answer.correct
              correct_count = correct_count + 1
            end
          end
          
        elsif question.checkbox
          
          max_correct = 0
          question.quiz_question_answers.each do |qqa|
            max_correct = max_correct + 1 if qqa.correct
          end
          
          multi_correct = 0
          multi_incorrect = 0
          quiz_attempt.quiz_attempt_answers.each do |answer|
            if answer.quiz_question_id == question.id && answer.correct
              multi_correct = multi_correct + 1
            elsif answer.quiz_question_id == question.id && !answer.correct
              multi_incorrect = multi_incorrect + 1
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
      entry.points = self.assignment.grade_item.points/self.quiz_questions.length.to_f * correct_count
      entry.save 
    end   
    # end assessment of answers
  end
  
end
