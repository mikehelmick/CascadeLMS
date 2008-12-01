class QuizQuestion < ActiveRecord::Base
  validates_presence_of :question

  belongs_to :quiz
  acts_as_list :scope => :quiz
  
  has_many :quiz_question_answers, :order => "position", :dependent => :destroy

  def validate
    errors.add_to_base( 'A question type must be chosen' ) unless text_response || multiple_choice || checkbox
  end

end
