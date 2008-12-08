class QuizAttemptAnswer < ActiveRecord::Base
  
  belongs_to :quiz_attempt
  belongs_to :quiz_question
  belongs_to :quiz_question_answer
  
end
