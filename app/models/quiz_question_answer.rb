class QuizQuestionAnswer < ActiveRecord::Base
  
  belongs_to :quiz_question
  acts_as_list :scope => :quiz_question
  
  
end
