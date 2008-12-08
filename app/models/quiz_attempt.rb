class QuizAttempt < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :quiz
  has_many :quiz_attempt_answers, :dependent => :destroy
  
end
