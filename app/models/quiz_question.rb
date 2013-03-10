class QuizQuestion < ActiveRecord::Base
  validates_presence_of :question

  belongs_to :quiz
  acts_as_list :scope => :quiz
  
  has_many :quiz_question_answers, :order => "position", :dependent => :destroy

  before_save :transform_markup

  def validate
    errors.add_to_base( 'A question type must be chosen' ) unless text_response || multiple_choice || checkbox
  end
  
  def transform_markup
	  self.question_html = self.question.apply_markup()
	  self.question_html = self.question_html[3..-1] if self.question_html[0..2].eql?("<p>")
	  self.question_html = self.question_html[0...-4] if self.question_html[-4..-1].eql?("</p>")
  end
end
